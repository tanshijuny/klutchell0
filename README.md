# balena-zoneminder

[zoneminder](https://www.zoneminder.com/) stack for balenaCloud

## Requirements

- NVIDIA Jetson Nano development board
- 32GB microSD card & reader
- External USB drive for video storage

## Getting Started

To get started can either sign up for a free balenaCloud account and push changes to your device remotely via Git.

<https://www.balena.io/docs/learn/getting-started/jetson-nano/>

Or you can skip the balenaCloud account and push changes to your device locally via the balena CLI.

<https://www.balena.io/os/docs/jetson-nano/getting-started/>

## Deployment

Deployment is carried out by downloading the project and pushing it to your device either via Git or the balena CLI.

<https://www.balena.io/docs/reference/balena-cli/>

```bash
# clone project
git clone https://github.com/klutchell/balena-zoneminder.git

# push to balenaCloud
balena login
balena push myApp

# OR push to a local device running balenaOS
balena push mydevice.local --env MYSQL_ROOT_PASSWORD=mysecretpw --env TZ=America/Toronto
```

### Application Environment Variables

Application envionment variables apply to all services within the application, and can be applied fleet-wide to apply to multiple devices.

|Name|Example|Purpose|
|---|---|---|
|`TZ`|`America/Toronto`|(optional) inform services of the [timezone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) in your location|
|`MYSQL_ROOT_PASSWORD`|`mysecretpw`|(required) provide a root password for the mysql database|

## Usage

## create database credentials

Connect to the `mariadb` Terminal and run the following:

```bash
mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES ON *.* TO 'zmuser'@'%' IDENTIFIED BY 'zmpass';"
```

Make sure `zmuser` and `zmpass` match the values provided for `ZM_DB_USER` and `ZM_DB_PASS` in `docker-compose.yml`.

## connect to dashboard

Once the database credentials are created you can restart the `zoneminder` service and connect to the dashboard to start adding monitors and storage.

<http://mydevice.local:80/zm>

### prepare external storage

Connect to the `Host OS` Terminal and run the following:

```bash
# o - clear the in memory partition table
# n - new partition
# p - primary partition
# 1 - partition number 1
# default - start at beginning of disk
# default - extend partition to end of disk
# w - write the partition table
printf "o\nn\np\n1\n\n\nw\n" | fdisk /dev/sda
mkfs.ext4 /dev/sda1 -L ZONEMINDER
```

Restart the `zoneminder` service and any partitions with the label `ZONEMINDER` will be mounted at `/media/{UUID}`.

The system path to the mount location(s) are printed in the logs.

Add the storage location in the ZoneMinder dashboard under Options -> Storage -> Add New Storage.

## Development

```bash
# cross build for aarch64 on an amd64 or i386 workstation with Docker
export DOCKER_CLI_EXPERIMENTAL=enabled
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
docker buildx create --use --driver docker-container
docker buildx build . --platform linux/arm64 --load --progress plain -t zoneminder
```

## Contributing

Please open an issue or submit a pull request with any features, fixes, or changes.

## Author

Kyle Harding <https://klutchell.dev>

[Buy me a beer](https://kyles-tip-jar.myshopify.com/cart/31356319498262:1?channel=buy_button)

[Buy me a craft beer](https://kyles-tip-jar.myshopify.com/cart/31356317859862:1?channel=buy_button)

## Acknowledgments

- <https://zoneminder.com/>
- <https://mariadb.com/>

## License

[MIT License](./LICENSE)
