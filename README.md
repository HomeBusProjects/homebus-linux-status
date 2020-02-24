# homebus-linux-status

This is a simple HomeBus data source which publishes the status of a Linux server.

## Usage

On its first run, `homebus-linux-status` needs to know how to find the HomeBus provisioning server.

```
bundle exec homebus-linux  -b homebus-server-IP-or-domain-name -P homebus-server-port
```

The port will usually be 80 (its default value).

Once it's provisioned it stores its provisioning information in `.env.provisioning`.

The software needs to be configured with a list of filesystems to monitor. Create a `.env`
file with a single variable in it, `MOUNT_POINTS`, set to a whitespace separated list of
filesystem mount points. For instance:
```
MOUNT_POINTS=/ /var/log /var/data
```

## Data Published

This program publishes the `org.homebus.experimental.server-status` DDC.
