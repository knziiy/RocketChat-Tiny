# RocketChat::Tiny

`RocketChat::Tiny` is a Perl module designed for interfacing with the Rocket Chat API.

## Synopsis

Use `RocketChat::Tiny` like this:

```perl
use RocketChat::Tiny;
my $chat = RocketChat::Tiny->new(
    url => "https://yourworkspace.rocket.chat",
    user => "username",
    password => "password",
    room => "roomname", # Optional
);
$chat->login;
$chat->post_message('This is a bot message!');

# To post to a room
$chat->post_message('This is a bot message!', channel => "#general");

# To post a direct message
$chat->post_message('This is a bot message!', channel => '@userFoo');
```

## Description

The `RocketChat::Tiny` module facilitates communication with Rocket Chat's Bot API, currently supporting the sending of text messages only.

### Methods

- `login`

  Obtains the token required for sending messages. The method returns the token, but it's stored within the object, so you don't need to capture the return value for use.

  ```perl
  my $token = $chat->login;
  ```

- `post_message`

  Sends a message. If no channel is specified, the message is sent to the room specified at instantiation. The channel can be either a room (prefixed with `#`) or a direct message to a user (prefixed with `@`).

  ```perl
  $chat->post_message('This is a bot message!', channel => "#room_name or @username");
  ```

- `send_message`

  This is an alternative method to `post_message` for sending messages to a specified room. Generally, you would use `post_message` for most cases.

  ```perl
  $chat->send_message('This is a bot message!', room => "room_name");
  ```

## Author

Kenji Kubo

## Copyright and License

Copyright (C) Kenji Kubo, 2024-

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
