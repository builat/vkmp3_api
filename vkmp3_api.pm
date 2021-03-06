#!/usr/bin/perl
package mp3vk_api;
use strict;
use warnings;

use Env qw(HOME);
use utf8;
use Encode;
use URI::Escape;
use HTML::Entities;
use LWP;
use LWP::Protocol::https;
use LWP::Simple;
use Parallel::ForkManager;

our $VERSION = 0.2;

#constructor
sub new {
  my ($class, %args) = @_;
     return ('Error in syntax usage') if(_arg_validation(\%args) != 1);

my $self = { 
      ua => _mk_ua(),
      login => $args{login},
      password => $args{password},
      dir =>$args{dir},
      threads=>30,
};
    
  bless $self, $class;

  die ('ERROR WITH CONNECTION AUTH') if($self->_connection_try() != 1);

  return $self;
}

#Creation of user agent. Private method
sub _mk_ua {
	my $ua = LWP::UserAgent->new();
		push @{ $ua->requests_redirectable }, 'POST';
	$ua->cookie_jar( {} );
return ($ua);
}

#public method. search via vk.
sub search {
  my ($self, $query) = @_;
  my $res = $self->{ua}->get('http://vk.com/search?c[section]=audio&c[q]='.uri_escape_utf8($query));
  eval{$res->is_success;} or return 'Error possible with LWP_ua see err msg -> '.$res->status_line;
#          my @findnings = $res->decoded_content =~  m'<input type="hidden" id="audio_info(.*?)</table>'sgi;
          my @findnings = $res->decoded_content =~  m'<div id="audio.*?>(.*?)<div class="ai_controls">'sgi;

                        my @dump;
                        push @dump, $self->_cleanup_response($_) for(@findnings);
                              @dump = grep { defined $_ } @dump;
  return (\@dump);
}

#parsing of vk response. private method
sub _cleanup_response {
  my ($self, $str) = @_;

  my ($title) = $str =~ m{<span class="ai_title">(.*?)</span>}si;
  return undef unless $title;
  $title =~ s/(<.*?>|\(.+\)|\&\w+|[;'"])//g;
  $title =~ s/\s+/ /g;
  $title = decode_entities($title);
  my ($duration) = $str =~ m{<div class="ai_dur" data-dur="\d+" onclick="audioplayer.switchTimeFormat(this, event);">(\d+:\d+)</div>}i;

  my ($link) = $str =~ m{value="(http://[^'"`]+\.mp3)}i;
  $duration = 0 unless($duration);
  
  return { title => $title, duration => $duration, link => $link };
}


#check posibility of connection
sub _connection_try{
  my $self = shift;
  my $res = $self->{ua}->post('https://login.vk.com/?act=login', {
      email => $self->{login},
      pass => $self->{password},
    });  

  if(  $res->is_success &&
      ($res->decoded_content =~ /var\s+vk\s*=\s*\{[^\{\}]*?id\s*\:\s*(\d+)/i
       || $res->decoded_content =~ m#login\.vk\.com/\?act=logout#i ) ) {
    $self->{id} = $1;
    return 1;
  }
  return 0;
}

#validation of login and passwd
sub _arg_validation {
        my $args = shift;
        unless (defined $args->{dir}){
                        $args->{dir} = "$ENV{HOME}/vk_music/";
                        mkdir $args->{dir};
        }
        else{
         $args->{dir} = "$ENV{HOME}/vk_music/$args->{dir}/"; 
         mkdir $args->{dir};
        }
        unless(defined $args->{login} && defined $args->{password}
                        && $args->{login} =~ /^.*?\@.*?$/  && $args->{password} =~ /\w{2,}/){
				return 0;
        }
        else{
                return 1;
        }
}


sub vk_download{
    my $self = shift;
    my $ref_dump = shift;
    my $pm = Parallel::ForkManager->new($self->{threads});
          foreach (@{$ref_dump}) {
         
                                                   $pm->start and next; # do the fork
                                                    if (getstore($_->{link}, "$self->{dir}/$_->{title}.mp3") != RC_OK){
                                                                  print 'error occured '."\n";
                                                    }
                                                    else{  
                                                                 print  $_->{title}.'.................. downloaded'."\n";
                                                    }      
                                                  $pm->finish; # do the exit in the child process
  }

       
}
1;
