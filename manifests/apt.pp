#
# This class is intended to serve as
# a way of configuring a custom APT repository
# for OpenStack packages.
#
# [location] either URL (as you would put in sources.list) or "ppa:user/ppa_name"
# [release] The release series to pull from (defaults to $lsbdistcodename)
# [repos] Components to use from the repository (defaults to "main")
# [key] ID of the signing key used in the repository
# [key_source] A URL for the public key identified by key
#
define openstack::apt(
  $location,
  $release = $::lsbdistcodename,
  $repos   = 'main',
  $https_proxy = undef,
  $key = undef,
  $key_source = undef,
  $pin_spec = undef) {

    if ($location =~ /^ppa:(\S+)\/(\S+)/) {
      $ppa_owner = "$1"
      $ppa_name = "$2"
      apt::ppa { "$location":
	https_proxy       => $https_proxy,
        release => $release
      } -> Package <| tag == "openstack" |>
      openstack::apt::pin { "pin-${name}":
        pin_spec => "release o=LP-PPA-${ppa_owner}-${ppa_name}"
      } -> Package <| tag == "openstack" |>
    } else {
      apt::source { "openstack-${name}":
        location          => $location,
        release           => $release,
        repos             => $repos,
        key               => $key,
        key_source        => $key_source,
        include_src       => false,
      } -> Package <| tag == "openstack" |>
      if ($pin_spec != undef) {
        openstack::apt::pin { "pin-${name}":
          pin_spec => $pin_spec
        } -> Package <| tag == "openstack" |>
      }
    }
}
