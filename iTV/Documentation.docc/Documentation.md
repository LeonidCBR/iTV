# ``iTV``

Discover and watch your favorite shows.

## Overview

iTV is an iOS app that allows users to watch TV content from streaming services.

### Features

- Fetching a list of TV channels from network API.
- Batch inserts to Core Data persistent storage using **NSBatchInsertRequest**.
- Pin your favorite channels.

@Row {
    @Column {
        ![An illustration displaying the UI for discovering of channels.](screenshot.png)
    }
    
    @Column {
        ![An illustration displaying the UI of favorite chammels.](screenshot2.png)
    }
}

## Topics

### Essentials

- ``Channel``
- ``ChannelProperties``

### Decoding data

- ``ChannelsDecoder``

### Services

- ``ChannelsProvider``
- ``NetworkProvider``
- ``ImageProvider``

### Persistence

- ``CoreDataStack``

### View controllers

- ``HomeController``
- ``VideoViewController``
