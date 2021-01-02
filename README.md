# [Server Factory](https://github.com/Server-Factory/Core-Framework) Utils

Various utils for [Server Factory](https://github.com/Server-Factory/Core-Framework) framework.

See the [current version](./version.txt) and
[version code](./version_code.txt).

## SSH login without password

To enable SSH login without a password use `init_ssh_access.sh` script. 
The script will generate an SSH key and incorporate it into the remote machine.


### How to use `init_ssh_access.sh` script

The script is accepting two parameters: 

- the remote host that into which we will incorporate SSH key for access
- port for SSH access on the remote server (this parameter is optional).

Example of use:

```
sh init_ssh_access.sh centos8.dev.local
```

or

```
sh init_ssh_access.sh 192.168.0.101
```

Once the script has been executed with success you can access the remote server as a root without providing the password:

```
ssh centos8.dev.local
```

or

```
ssh root@192.168.0.101
```

## Obtaining the host's IP address

To obtain an IP address based on the hostname you can use a `getip.sh` script.

### How to use `getip.sh` script

The script accepts one parameter:
- Name of the host.

Example of use:

```
sh getip.sh google.com
```

or

```
sh getip.sh localhost
```

or mDNS powered host:

```
sh getip.sh some_machine.local
```
## Tunneling

To create a tunnel between your machine and remote machine service you can use a `tunnel.sh` script.

### How to use the `tunnel.sh` script

The script accepts two parameters:

- Port to use on localhost side (will be tunneled to the same port on the remote side)
- Remote host

Example of use:

```
sh tunnel.sh 35432 centos8.dev.local
```

or

```
sh tunnel.sh 35432 root@192.168.0.101
```

Now we can access this service locally on port 35432:

```
telnet 127.0.0.1 35432
```

## What's new?

To see what is new in the current version please see the [changelog](./CHANGELOG.md).

