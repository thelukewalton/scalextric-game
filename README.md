# Overview

This file describes how to set up the Scalextric game.

This system operates by having the RFID reader send tag reads to the laptop (server). The server runs a Docker image written in Dart, which acts as the central hub. It includes a database to store overall lap times and individual fastest laps. All communication is routed through this server, meaning the front-end app and RFID reader do not communicate directly.

The front-end app, developed in Flutter, allows for basic configuration. To update configuration settings while the app is running, long-press the settings button on the leaderboards page.

## Hardware setup

Connect RFID reader, android kiosk and laptop to the TP Link router using the **orange** LAN ports. Once connected, they should be assigned IP addresses as shown in the table above.

### Changes

This is a git repo. I _may_ have made more changes since this was last updated. To check this, run `git pull` in the terminal (you will need internet connection). If there are changes:

1. Run `docker compose down` and then `docker compose up --build -d`. This will rebuild the backend and restart the server.
2. Rebuild the app. Hopefully, the apk in the top level directory will be the latest build, but if you need to rebuild it:

```bash
cd packages/frontend
flutter build apk --target-platform android-arm64
cp build/app/outputs/flutter-apk/app-release.apk ../../app.apk
cd ../..
```

To install this, run `adb install app.apk`.

#### Copying files to KC50

If you want to copy files, such as images to the KC50, use the following command:
` adb push /FILENAME /COPIEDNAME`

For instance, to copy the devcon logo, I used the command:
`adb push packages/frontend/assets/devcondark.png /sdcard/Download`.

The app supports custom images for cars 1 and 2, the track and a branding image. This branding image **must** be a black background and be in landscape.

## RFID Reader Setup

1. Navigate to the [RFID Reader web portal](https://fx7500805943.local)
2. Login with password
3. Turn on connection to server: Communication -> Zebra IoT connector -> Connection -> Disable `Autoconnect` and the click 'Connect'. You may have to enter your password again.
   > It is not recommended to turn on Auto Connect

# Staging

The following notes should only be needed in a catastrophe. Hopefully the staging will always be set up in advance.

## Android Kiosk

- If device is brand new, follow the on screen set up guide. Device can be set up offline.
- Ensure device is running Android 13 (flutter datawedge not currently working on Android 14).
- Connect Ethernet: Settings -> Network and Internet -> Ethernet -> Turn on
- Set display scaling: Settings -> Display -> Display size and text -> Set display size to smallest value.
- Set display brightness: Settings -> Display -> Turn off "Adaptive Brightness" and set the brightness level slider to the desired value.
- Turn off vibration: Settings -> Sound and Vibration -> Vibration and haptics -> Use Vibration and haptics - Off. I would also recommend musting all of the volume sliders at the top apart from media volume.

Optional
If you need to debug the application, follow these steps

- Enable developer mode: About Phone -> Tap build number 7 times.
- Enable USB Debugging: System -> Developer Options -> USB Debugging -> Allow
- Now you should be able to run the flutter app. See [Frontend](./frontend/README.md) for more information.

## RFID Reader

Create IOT configuration:

1.  Navigate to the [RFID Reader web portal](https://192.168.0.102)
2.  Login with password
3.  Navigate to: Communication -> Zebra IoT Connector -> Configuration
4.  Select 'Add Endpoint'
5.  Select Endpoint type: MQTT. Endpoint name and description can be set to any values
6.  Apply the following settings:
    Server: 192.168.0.101
    Port: 1883
    Protocol: TLS
    Client Id: rfid
    Username: zebra
    Password:
7.  Navigate to Topics section. Apply the following topics:
    Tag Data events:

            - Topic: /rfid

    Management:

            - Command: Topic: /rfid/control
            - Response: Topic: /rfid/control-resp

8.  Leave all other options blank.
9.  Save / apply settings
10. In the interface Configuration, set `Tag Data Interface 1` and `Management Events Interface` to be the name of the configuration you just created.
11. Navigate to Communication -> Zebra IoT Connector -> Connection. Disable Autoconnect, and then click connect. You may have to enter the password again.

## FS Camera

The camera should be using IP address 192.168.0.106. This will save images into an FTP server which is hosted within docker. This FTP server saves files onto the linux laptop directory /home/scalextric/Desktop/dmo-scalextric/docker/ftp. The app will show whatever jpg image is placed into that directory.

If images are not appearing: first ensure the camera is visible on the network - using the linux laptop navigate to its IP address in the browser. If the camera is connected, check if it is alerting to FTP failing. If that is the case, most often the issue is due to permissions on the folder. Ensure the user has read and write access to the folder where images are saved.

## Docker

```
docker compose up
```

> If you get error `external volume "db" not found`, run: `docker volume create db`

If you need to rebuild the image:

```bash
docker compose up --build
```

You should only need to build the image on the first run on a new machine, or when changes have been made to the backend.

On the first run, you will need to send a GET request to the `/setup` endpoint. This will initialize the database. If you think you already have a database, this will delete it.

```curl
GET http://localhost:13000/setup
```
