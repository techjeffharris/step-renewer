# step-renewer

A one-shot systemd service with timer for renewing a certificate using a [Step CA](https://smallstep.com/docs/step-ca/certificate-authority-server-production) server's ACME provisioner.

By default, on every hour between midnight and 5am (+ a random duration between 0s and 5m), the timer will start the service. The service checks to see whether the certificate will expire within `RENEWAL_THRESHOLD`, and if so, renews the certificate then passes the contens of `EXEC_START_POST` to `bash -c`.

## Supported Operating Systems

This has been tested on the following operating systems but should work on derivatives based on these as well:
* Debain 11 (Bullseye)
* Debian 12 (Bookworm)

## Dependencies
* A functioning step-ca server configured with an ACME provisioner. Smallstep has several good tutorials. I like this one: [Build a Tiny Certificate Authority For Your Homelab](https://smallstep.com/blog/build-a-tiny-ca-with-raspberry-pi-yubikey/)
* systemd version 243 or newer. There is a workaround for some older systems. See [step-renewer.service](#step-renewer.service) below for details.
* [step-cli](https://smallstep.com/docs/step-cli/). See [Install Dependencies](#Install-Dependencies) below for instructions.

## Getting Started

1. [System Prep](#System-Prep)
2. [Install Dependencies](#Install-Dependencies)
3. [Clone or download](#Clone-or-Download)
4. [Configure](#Configure)
5. [Install](#Install)

### System Prep
When requesting certificates using the ACME protocol [HTTP-01 challenge](https://letsencrypt.org/docs/challenge-types/#http-01-challenge) the step-ca host must be able to resolve the hostname specified in the challenge request. By default, step-renewer uses `hostname -f` to determine the hostname used in the ACME HTTP-01 challenge request; therefore, configuring your system's Fully Qualified Domain Name is recommended.

### Install Dependencies
You will need to install the Step CLI tool on all servers using step-renewer. The step CLI tool can also be used to install your root certificate into the system trust store on clients.

Follow the official instructions for your distribution: [Install step](https://smallstep.com/docs/step-cli/installation)

### Bootstrap Step CLI

You will need the sha256 fingerprint of you root certificate authority certificate. You can use the below command to get the fingerprint:
```bash
openssl x509 -in /path/to/root_ca.crt -sha256 -fingerprint -noout | cut -d "=" -f 2 | sed 's/://g'
```

Once you have your fingerprint (assigned to `$FINGERPRINT` in this example), configure step to download your root certificate and install it into the system's trust store:
```bash
step ca bootstrap --install \
--ca-url https://ca.example.home.arpa:443 \
--fingerprint $FINGERPRINT
```

### Clone or Download step-renewer

Either clone or download this repo. By default, it should be installed to /etc/step-renewer, but you can configure whatever path you would prefer. See [Configuration Options](#Configuration-Options) below for details.

#### Clone git repository
```bash
cd /etc
git clone https://github.com/techjeffharris/step-renewer.git
cd /etc/step-renewer
```

### Install
Run the installation script.

```bash
./install.sh
```

The installation script will request a certificate as configured but with a very short lifespan, wait a few seconds for the certificate to be eligible for renewal, then install and enable the step-renewer service and timer units. The service will see that the short-lived cert is eliglble for renewal and request a new certificate as per the configured frequency and expiration time. If all goes well, you will see the output of `systemctl status step-renewer.service`.

### Configure

During installation, `step-renewer.cfg` will be copied from `step-renewer.cfg.default` if it does not already exist. You may choose to modify `step-renewer.cfg` to suit your needs. See [Configuration Options](#Configuration-Options) below for details.

#### `EXEC_START_POST`

After installation, the one option you will almost certainly want to modify is `EXEC_START_POST` which specifies a custom script to be run after successful renewal, such as restarting nginx.

#### systemd service and timer

The installation script symlinks `step-renewer.service` and `step-renewer.timer` into `/etc/systemd/system` so they can be modified directly from `STEP_RENEWER_PATH`.

##### step-renewer.service
By default, the service uses the `ExecCondition` option to only renew the certificate when it needs to be renewed. ExecCondition was added to systemd in version 243, so Debian 11 and newer will work out of the box. However, if your system uses a version older than 243, you can use `ExecStartPre` option instead. See the [systemd.service](https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html#ExecCondition=) manpage for details.

##### step-renewer.timer
By default, the timer runs between 0 and 5 am every day and this is defined in `step-renewer.timer` using the OnCalendar option. See [Timer unit configuration - OnCalendar](https://www.freedesktop.org/software/systemd/man/latest/systemd.timer.html#OnCalendar=) for details on configuring systemd timers.

#### Configuration Notes
* If `RENEWAL_FREQUENCY` or `RENEWAL_TIME` do not comply with the Step CA server's signing policies, certificate renewal will fail.

#### Configuration Options
* `STEP_RENEWER_PATH=/etc/step-renewer` - The path to the step-renewer project.
* `STEPPATH=/root/.step` - The path to the local Step CLI configuration. See [Environment Variables](https://smallstep.com/docs/step-cli/the-step-command#environment-variables) in the `step` command documentation.
* `#HTTP_LISTEN=:80` - Use a non-standard http address, behind a reverse proxy or load balancer, for serving ACME challenges. This option is disabled by default. See the `--http_listen` option in the [step ca certificate](https://smallstep.com/docs/step-cli/reference/ca/certificate#options) documentation. *Note: as per the ACME HTTP-01 challenge spec, only port 80 or 443 are allowed.* See [HTTP-01 challenge](https://letsencrypt.org/docs/challenge-types/#http-01-challenge) for details.
* `#WEBROOT=/var/www/html` - If an existing webserver is using port 80, you can specify the path to the WEBROOT where step-ca will place a temporary file for verification rather than running a standalone server on port 80. This option is disabled by default. See the --webroot option in the [step ca certificate](https://smallstep.com/docs/step-cli/reference/ca/certificate#options) documentation.
* `HOSTNAME=$(hostname -f)` - The hostname for which we will request a certificate, used as the common name and Subject Alternate Name. The Step CA server's DNS server must resolve `hostname` to one of this machine's IP addresses.
* `CERT_LOCATION=/etc/step-renewer/localhost.crt` - The path to the certificate.
* `KEY_LOCATION=/etc/step-renewer/localhost.key` - The path to the key.
* `KTY=EC` - Key type. EC by default, but some applications require RSA. See the `--kty` option in the [step ca certificate](https://smallstep.com/docs/step-cli/reference/ca/certificate#options) documentation.
* `RENEWAL_FREQUENCY="1 day"` - How often we want to renew the certificate, minimum 1 day. See [Date input formats](https://www.gnu.org/software/coreutils/manual/html_node/Date-input-formats.html) in the [GNU coreutils manual](https://www.gnu.org/software/coreutils/manual/) for more information.
* `RENEWAL_THRESHOLD="5 hours"` - The certificate may be renewed if it expires within `RENEWAL_THRESHOLD`. See [Relative items in date strings](https://www.gnu.org/software/coreutils/manual/html_node/Relative-items-in-date-strings.html) in the [GNU coreutils manual](https://www.gnu.org/software/coreutils/manual/) for more information.
* `EXPIRATION_TIME="5:00"` - Time of the day that the certificate should expire. See [Date input formats](https://www.gnu.org/software/coreutils/manual/html_node/Date-input-formats.html) for more information.
* `EXEC_START_POST=` - an optional script to run after the certificate has been renewed.

