#!/usr/bin/perl -w
use strict;
use warnings;
use Data::Dumper;
use Digest::SHA qw(sha512);
use Crypt::OpenSSL::Random;
use Crypt::OpenSSL::RSA;
use IO::File;
 

my $passphrase = 'manukeerampanal';
my $plaintext = 'India is my country.';

if(@ARGV && $ARGV[0] == 1) 
{
    my $private_key = '';
    my $ciphertext  = '';
    
    {
        local $/ = undef;
        my $fh   = IO::File->new;
        open($fh, "<","./key.private") or die "Couldn't open file ./key.private, $!";
        $private_key = <$fh>;
        close $fh;
    }
    {
        local $/ = undef;
        my $fh   = IO::File->new;
        open($fh, "<","./mydata.txt") or die "Couldn't open file ./mydata.txt, $!";
        $ciphertext= <$fh>;
        close $fh;
    }
    
    my $rsa_priv = Crypt::OpenSSL::RSA->new_private_key($private_key);
    my $plaintxt = $rsa_priv->decrypt($ciphertext);
    
    print $plaintxt . "\n\n\n";
}
else
{

    # not necessary if we have /dev/random:
    Crypt::OpenSSL::Random::random_seed(genrsarandom(1024));
    Crypt::OpenSSL::RSA->import_random_seed();
    my $rsa = Crypt::OpenSSL::RSA->generate_key(1024);
    my $private_key = $rsa->get_private_key_string();
    #my $publick_key = $rsa->get_public_key_string();
    my $publick_key = $rsa->get_public_key_x509_string();
    print "private key is:\n", 
            $private_key . "\n\n\n";
    print "public key (in PKCS1 format) is:\n",
            $publick_key . "\n\n\n";
    print "public key (in X509 format) is:\n",
            $rsa->get_public_key_x509_string()."\n\n\n";
    {
        my $fh = IO::File->new;
        open($fh, ">./key.private") or die "Couldn't open file ./key.private, $!";
        print $fh $private_key;
        close $fh;
    }
    
    {
        my $fh = IO::File->new;
        open($fh, ">./key.public") or die "Couldn't open file ./key.public, $!";
        print $fh $publick_key;
        close $fh;
    }
    
    my $rsa_pub = Crypt::OpenSSL::RSA->new_public_key($publick_key);
    my $ciphertext = $rsa_pub->encrypt($plaintext);
    
    {
        my $fh = IO::File->new;
        open($fh, ">./mydata.txt") or die "Couldn't open file ./mydata.txt, $!";
        print $fh $ciphertext;
        close $fh;
    }
    
    my $rsa_priv = Crypt::OpenSSL::RSA->new_private_key($private_key);
    my $plaintxt = $rsa_priv->decrypt($ciphertext);

}

sub genrsarandom {
    my $bytes = $_[0];
    my $randomdata = "";
    my $numberofrounds = int($bytes / 64) + 1;

    for (my $i = 0; $i < $numberofrounds; $i++) {
        $randomdata = $randomdata . sha512($passphrase . sha512($i.$i));
    }

    $randomdata = substr($randomdata, 0, $bytes);
    my $prngdata = $randomdata;
    return $prngdata;
}
