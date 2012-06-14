#
# This class is intended to serve as
# a way of configuring a custom APT repository
# for OpenStack packages.
#
# [location] URL (as you would put in sources.list)
# [release] The release series to pull from (defaults to $lsbdistcodename)
# [repos] Components to use from the repository (defaults to "main")
# [key] ID of the signing key used in the repository
# [key_source] A URL for the public key identified by key
#
class openstack::apt(
  $location,
  $release = $lsbdistcodename,
  $repos   = 'main',
  $key,
  $key_source) {
        apt::source { "cisco_openstack":
                location          => $location,
                release           => $release,
                repos             => $repos,
                key               => $key,
                key_source        => $key_source,
                include_src       => false,
        } -> Package <| tag == "openstack" |>
}
