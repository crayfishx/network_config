
# 1.1.0

* Added `dns3` option

# 1.0.1

* Use the Puppet Type API to force loading of a ini_setting provider.  Fixes an issue in Puppet 4 where `puppet/util/ini_file` cannot be loaded. 


# 1.0.0

* Puppet 4 compatibility - 1.x will not work with Puppet 4.x
* Bugfix: Removed inline template code for evaluating bonds that fails on Puppet 4

#### 0.13.3

* Fix: Dont purge ip_allocations in non-managed interfaces if `purge_interfaces` is set to false

#### 0.13.2: N/A no change

#### 0.13.1

* Bugfixes, fix clashes between GATEWAY= and GATEWAY0,1,2= settings when on NM controlled systems

### 0.13.0

* Internal refactoring of provider code to centralize functionality into a shared provider
* Added `ip_route` type and provider for managing static interface routes
* Added `routes` option to the `ifconfig` hash for configuring static routes


### 0.12.0

* Added gateway attribute to `network_interface` type

#### 0.11.1

* Bugfix:  When prefetching interfaces, if an interface is found with no `NAME=` parameter, it is simply ignored and doesnt cause en exception.

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

