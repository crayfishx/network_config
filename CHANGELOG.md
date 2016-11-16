### 0.11.0

* Fixed: `nm_controlled` attribute was not being managed by `network::interface`
* Added `peerdns` attribute

### 0.10.0

* Added `bond_defaults` option

#### 0.9.1

* Fixed unquoted hash key which fails to compile on Puppet 3

### 0.9.0

* Purging will exclude interfaces listed in $exclude_if

#### 0.8.1

* fixed forge dependencies


### 0.8.0

* Added purging feature for ip_allocations and network_interfaces


### 0.7.0

* Improved handling of service or interface restarts
* Fix for Puppet 3.6 parser
* Added destroy feature for network_interface

### 0.6.0

- Changed how interface services detect if an interface is up or down


### 0.5.0

- Initial public release

