package RocketChat::Tiny;
use utf8;
use strict;
use warnings;

use JSON;
use LWP::UserAgent;
use LWP::Protocol::https;
use HTTP::Request;
use HTTP::Request::Common qw/POST/;

our $VERSION = '0.01';

sub new {
    my ($class, %args) = @_;
    my $self = {};
    for (qw/url room user password/) {
        $self->{$_} = $args{$_};
    }

    $self->{ua} = LWP::UserAgent->new(ssl_opts => { verify_hostname => 1 });
    
    return bless $self, $class;
}

sub _request {
    my ($self, $method, $uri, $headers, $content) = @_;
    my $req = HTTP::Request->new($method => $uri);
    for my $header (keys %$headers) {
        $req->header($header => $headers->{$header});
    }
    $req->content(encode_json($content)) if $content;

    my $res = $self->{ua}->request($req);
    
    unless ($res->is_success) {
        return (0, $res->status_line);
    }
    return (1, decode_json($res->content));
}

# https://developer.rocket.chat/reference/api/rest-api/endpoints/other-important-endpoints/authentication-endpoints/login
sub login {
    my ($self) = @_;
    
    my $uri = URI->new($self->{url} . "/api/v1/login");
    my ($success, $result) = 
        $self->_request(
            'POST', 
            $uri, 
            {'Content-Type' => 'application/json; charset=UTF-8'}, 
            {user => $self->{user}, password => $self->{password}}
        );
    
    unless ($success) {
        die $result;
    }

    $self->{authToken} = $result->{data}->{authToken};
    $self->{userId} = $result->{data}->{userId};

    return $self->{authToken};
}

sub get_room_id {
    my ($self, $room_name) = @_;
    
    unless ($room_name) {
        die "Room name not specified.";
    }
    unless ($self->{authToken} && $self->{userId}) {
        die "AuthToken and UserId are undefined. Please login first.";
    }

    my $uri = URI->new($self->{url} . "/api/v1/rooms.info");
    $uri->query_form(roomName => $room_name);
    
    my ($success, $result) = 
        $self->_request(
            'GET', 
            $uri, 
            {'X-Auth-Token' => $self->{authToken}, 'X-User-Id' => $self->{userId}}, 
            {}
        );
    
    unless ($success) {
        die $result;
    }

    return $result->{room}->{_id};
}


sub send_message {
    my ($self, $message, %args) = @_;
    
    unless ($self->{authToken} && $self->{userId}) {
        die "AuthToken and UserId are undefined. Please login first.";
    }

    my $room = $args{room} || $self->{room};
    my $room_id = $self->get_room_id($room);
    unless ($room_id) {
        die "Failed to get Room ID.";
    }

    my $params = {
        message => {
            rid => $room_id,
            msg => $message,
        }
    };
    
    my $uri = URI->new($self->{url} . "/api/v1/chat.sendMessage");
    my ($success, $result) = 
        $self->_request(
            'POST', 
            $uri, 
            {'Content-Type' => 'application/json; charset=UTF-8', 'X-Auth-Token' => $self->{authToken}, 'X-User-Id' => $self->{userId}}, 
            $params
        );
    
    unless ($success) {
        die $result;
    }

    return 1;
}


# https://developer.rocket.chat/reference/api/rest-api/endpoints/team-collaboration-endpoints/chat-endpoints/postmessage
sub post_message {
    my ($self, $message, %args) = @_;
    
    unless ($self->{authToken} && $self->{userId}) {
        die "AuthToken and UserId are undefined. Please login first.";
    }

    my $channel = $args{channel} || "#" . $self->{room};
    my $params = {
        channel => $channel,
        text => $message,
    };

    my $uri = URI->new($self->{url} . "/api/v1/chat.postMessage");
    my ($success, $result) = $self->_request('POST', $uri, {'Content-Type' => 'application/json; charset=UTF-8', 'X-Auth-Token' => $self->{authToken}, 'X-User-Id' => $self->{userId}}, $params);
    
    unless ($success) {
        die $result;
    }

    return 1;
}


1;
__END__

=head1 NAME

RocketChat::Tiny - A Perl module for interfacing with the Rocket Chat API

=head1 SYNOPSIS

  use RocketChat::Tiny;
  my $chat = RocketChat::Tiny->new(
      url => "https://yourworkspace.rocket.chat",
      user => "username",
      password => "password",
      room => "roomname",
  );
  $chat->login;
  $chat->post_message('This is a bot message!');
  
  # To a room
  $chat->post_message('This is a bot message!', channel => "#general");

  # To a direct message
  $chat->post_message('This is a bot message!', channel => '@userFoo');

=head1 DESCRIPTION

The C<RocketChat::Tiny> module facilitates communication with the Rocket Chat's Bot API, currently supporting only the sending of text messages.

=over 4

=item login

my $token = $chat->login;

Obtains the token required for sending messages. Although the method returns the token, it is stored within the object, so it's not necessary to capture the return value for use.

=item post_message

$chat->post_message('This is a bot message!', channel => "#room_name or @username");

Sends a message. If no channel is specified, the room specified at creation is used. 
The channel can be either a room (channel) or a user, specified as follows:

  #channel_name
  @username

=item send_message

$chat->send_message('This is a bot message!', room => "room_name");

Sends a message. If no room is specified, the room specified at creation is used. 

Sends a message to the specified room. Typically, using post_message should suffice.

=back

=head1 SEE ALSO

=head1 AUTHOR

Kenji Kubo

=head1 COPYRIGHT AND LICENSE

Copyright (C) Kenji Kubo, 2024-

This module is free software; you can redistribute it and/or modify it under the same terms as
