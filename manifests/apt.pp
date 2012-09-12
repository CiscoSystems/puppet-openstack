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
  $key = false,
  $key_source = false) {

    if ($location =~ /^ppa:/) {
      apt::ppa { "$location":
        release => $release
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
    }
}
