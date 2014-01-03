#!/usr/bin/perl
use warnings;
use strict;
use v5.18;
use mp3vk_api;
use utf8;
 
my $vk = mp3vk_api->new(	login => 'mail@mail.com', 
							password => 'passwd',
							dir =>'Rhapsody',
							threads=>'10',
);
 
  my $out = $vk->search('Rhapsody');
 my $a = $vk->vk_download($out);
