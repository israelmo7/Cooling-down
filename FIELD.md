# Field

Three folders. Android and iOS use the same tablet app.

## 1. tablets

Install this app on every tablet.

In the tablet settings, enter:

- computer address: `http://<shop-computer>:8080`
- the token from the shop computer
- the place name (the same name on every tablet that shares one fridge area)

Tablets send check-in and check-out over the shop Wi-Fi. They do not use SSH.

## 2. server-ssh

This is the shop program.

On your computer, with Docker, while SSH to the shop computer already works:

```bash
server-ssh/deploy.sh user@shop-pc
```

The program keeps its database and settings in `~/cooling-down/data/` on the shop computer.

Open `~/cooling-down/data/.env` and set the admin login and the mail fields. If the token line was empty, the program writes one and prints it. Copy that token onto the tablets. After editing the file:

```bash
ssh user@shop-pc 'cd ~/cooling-down && docker compose up -d --force-recreate'
```

The admin page is `http://<shop-computer>:8080/admin`.

To open SSH for the next visit, stand at the shop computer and run:

```bash
sudo sh ~/cooling-down/ssh-window.sh 30
```

SSH stays open for 30 minutes, then closes. It stays closed after a reboot.

## 3. server-usb

Use this only when the shop computer does not already have Docker or SSH.

On an Ubuntu computer with internet, the same Ubuntu version as the shop PC:

```bash
sudo sh server-usb/fetch-packages.sh
```

Copy the `server-usb` folder to a USB stick. On the shop computer:

```bash
sudo sh install.sh
```

Log out and back in. Then use `server-ssh/deploy.sh` from your computer.

If the shop computer already has internet and apt, `install.sh` can install Docker and SSH without the downloaded packages.
