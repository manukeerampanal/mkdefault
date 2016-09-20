package mkdefault;
use strict;
use warnings;
use Data::Dumper;
use File::Basename;
#use experimental 'smartmatch';
use vars qw(%GLOB %CUST_GLOBAL $dbh %ENV $curdate1 $curdate2 $AUTOLOAD $name);
use DBI;
use POSIX qw(strftime);
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(is_array is_hash is_nan %GLOB);
sub new {
	my $curdate1=strftime "%Y-%m-%d", localtime;
	my $curdate2=strftime "%F %r %Z(%z)", localtime;
	my $current_dir=dirname(__FILE__);
    my $class = shift;
    my $self = bless {}, $class;
    my %hash = @_;
	require "./global.config";
	my $config_file="Leads.setup";
    if (exists($hash{config_file})) {
		$config_file=$hash{config_file};
    }
    require $CUST_GLOBAL{main_config_file_path}.$config_file;
	$self->{config_file}=$config_file;
    $CUST_GLOBAL{error}{error_log}=exists($hash{error_log})?$hash{error_log}:$CUST_GLOBAL{error}{error_log_path};
	my $error_log_file=$CUST_GLOBAL{error}{error_log}."/error.";
    if (exists($hash{script})) {
		$error_log_file.=$hash{script}.".";
    }
	$error_log_file.=$curdate1.".log";
	$CUST_GLOBAL{current_execiton_script}=$hash{script};
	open(CUSTERR,">>", $error_log_file) or die "Can't open log $error_log_file";
	#open(STDOUT, ">>", $error_log_file) or die "Can't open log $error_log_file";
	#open(STDERR, ">>", $error_log_file) or die "Can't open log $error_log_file";
	my $process_id=&creatprocessId();
	print STDOUT "\n\n\n************************************  $curdate2  ***************************************** --- START\n\n\n";
	print STDOUT "Process # : ".$process_id."\n";
	print CUSTERR "\n\n\n************************************  $curdate2  ***************************************** --- START\n\n\n";
	print CUSTERR "Process # : ".$process_id."\n";
    $self->_initialize(@_);
	$self->{process_id}=$process_id;
	$self->{process_time}=$curdate2;
	$self->{error_log_file}=$error_log_file;
    return $self;
}
sub _initialize {
    my $self = shift;
    my %hash = @_;
    $self->{host} = $CUST_GLOBAL{db}{host};
    $self->{port} = $CUST_GLOBAL{db}{port};
    $self->{username} = $CUST_GLOBAL{db}{username};
    $self->{password} = $CUST_GLOBAL{db}{password};
    $self->{dbname} = $CUST_GLOBAL{db}{name};
    $self->{connect_driver} = $CUST_GLOBAL{db}{driver};
    if (exists($hash{host})) {
        $self->{host} = $hash{host};
    }
    if (exists($hash{port})) {
        $self->{port} = $hash{port};
    }
    if (exists($hash{username})) {
        $self->{username} = $hash{username};
    }
    if (exists($hash{password})) {
        $self->{password} = $hash{password};
    }
    if (exists($hash{dbname})) {
        $self->{dbname} = $hash{dbname};
    }
    if (exists($hash{connect_driver})) {
        $self->{connect_driver} = $hash{driver};
    }
}
sub getDBConnection {
    my $self = shift;
    my %hash = @_;
    if (exists($hash{host})) {
        $self->{host} = $hash{host};
    }
    if (exists($hash{port})) {
        $self->{port} = $hash{port};
    }
    if (exists($hash{username})) {
        $self->{username} = $hash{username};
    }
    if (exists($hash{password})) {
        $self->{password} = $hash{password};
    }
    if (exists($hash{dbname})) {
        $self->{dbname} = $hash{dbname};
    }
    if (exists($hash{connect_driver})) {
        $self->{connect_driver} = $hash{driver};
    }
    my $extra .= "host=$self->{host};" if $self->{host};
    $extra .= "port=$self->{port};" if $self->{port};
    my $temp_dbh = DBI->connect("DBI:$self->{connect_driver}:database=$self->{dbname};$extra", $self->{username}, $self->{password},{AutoCommit => 1});
    if(!$temp_dbh){
        $self->printFatalError("head"=>"MySql Error","message"=>qq{MySQL Connection Error to host }.$self->{host}.qq{. Database Connection Failed. DB Name :-}.$self->{dbname}.qq{.});
    }
    $temp_dbh->{HandleError} = sub {
        my ($errmsg, $h) = @_;
        $self->printFatalError("head"=>qq{MySQL Error},"message"=>$errmsg.qq{. DB Name :-$CUST_GLOBAL{db}{name}. --- }.$self->{process_id}."--".$self->{host}."--".$self->{username});
    };
	return ($temp_dbh);
}
sub printFatalError {
    my $self = shift;
    my %hash = @_;
    my($heading,$message) = ($hash{head},$hash{message});
    print STDERR qq{\033[0;31m FatalError --> $heading :- $message \033[m \n};
    print CUSTERR qq{\033[0;31m FatalError --> $heading :- $message \033[m \n};
	$self->mailSender("from"=>$CUST_GLOBAL{error}{email}{err_from},"to"=>$CUST_GLOBAL{error}{email}{err_to},"cc"=>$CUST_GLOBAL{error}{email}{err_cc},"bcc"=>$CUST_GLOBAL{error}{email}{err_bcc},"subject"=>qq{Debtor Addition Scheduler FatalError - $heading},"body"=>"FatalError -- $heading :- $message");
    #exit(1);
	return 0;
}
sub printError {
    my $self = shift;
    my %hash = @_;
    my($heading,$message) = ($hash{head},$hash{message});
    print STDERR qq{\033[0;91m Error --> $heading :- $message \033[m \n};
    print CUSTERR qq{\033[0;91m Error --> $heading :- $message \033[m \n};
	$self->mailSender("from"=>$CUST_GLOBAL{error}{email}{err_from},"to"=>$CUST_GLOBAL{error}{email}{err_to},"cc"=>$CUST_GLOBAL{error}{email}{err_cc},"bcc"=>$CUST_GLOBAL{error}{email}{err_bcc},"subject"=>qq{Debtor Addition Scheduler Error - $heading},"body"=>"Error -- $heading :- $message");
    return 0;
}
sub printWarning {
    my $self = shift;
    my %hash = @_;
    my($heading,$message) = ($hash{head},$hash{message});
    print STDERR qq{\033[0;33m Warning --> $heading :- $message \033[m \n};
    print CUSTERR qq{\033[0;33m Warning --> $heading :- $message \033[m \n};
    return 1;
}
sub printOutput {
    my $self = shift;
    my %hash = @_;
    my($heading,$message) = ($hash{head},$hash{message});
    print STDOUT qq{\033[0;32m Output --> $heading :- $message \033[m \n};
    print CUSTERR qq{\033[0;32m Output --> $heading :- $message \033[m \n};
    return 1;
}
sub printInfo {
    my $self = shift;
    my %hash = @_;
    my($heading,$message) = ($hash{head},$hash{message});
    print STDOUT qq{ Info --> $heading :- $message  \n};
    print CUSTERR qq{ Info --> $heading :- $message  \n};
    return 1;
}
sub mailSender {
	use Mail::Sender;
    my $self = shift;
    my %hash = @_;
	my ($from,$to,$cc,$bcc,$subject,$body)=($hash{from},$hash{to},$hash{cc},$hash{bcc},$hash{subject},$hash{body});
	my $smtphost=(exists($hash{smtpserver}) && $hash{smtpserver} ne '')?$hash{smtpserver}:$CUST_GLOBAL{email}{smtp_host};
    if (exists($hash{from})) {
        $from = $hash{from};
    }
    $hash{ctype}=(exists($hash{ctype}) && $hash{ctype} ne '')?$hash{ctype}:'text/html; charset=us-ascii';
    $hash{priority}=(exists($hash{priority}) && $hash{priority} ne '' && $hash{priority} > 0)?$hash{priority}:3;
    my $priority = $hash{priority};
	my $sender = new Mail::Sender{
		smtp        =>  $smtphost,
		from        =>  $from,
		on_errors   =>  'code',
        priority    =>  $priority
	};
	$Mail::Sender::NO_X_MAILER = 1;
    if(defined($hash{file}) && $hash{file} ne '') {
        $sender->OpenMultipart({
            to          =>  $to,
            cc          =>  $cc,
            bcc         =>  $bcc,
            subject     =>  $subject,
            headers     =>  $CUST_GLOBAL{email}{email_header},
        }) or return $self->printError("head"=>"Mail Send Status","message"=>"Cannot send mail: $Mail::Sender::Error");
        my @temp_file=split(',',$hash{file});
        my @temp_file_name=split(',',$hash{file_name});
        $sender->Body({charset => 'US-ASCII',encoding => 'utf8',ctype => $hash{ctype},msg=>$body."\n"});
        for(my $a=0;$a<=$#temp_file;$a++) {
            $sender->Attach({
                description => $hash{description},
                ctype => 'application/octet-stream',
                encoding => 'Base64',
                disposition => 'attachment; filename="'.$temp_file_name[$a].'"',
                file => $temp_file[$a]
            });
            
        }
        $sender->Close();
    } else {
        my %mail_data=(
            ctype       =>  $hash{ctype},
            headers     =>  $CUST_GLOBAL{email}{email_header},
            to          =>  $to,
            cc          =>  $cc,
            bcc         =>  $bcc,
            subject     =>  $subject,
            msg         =>  $body
        );
        if(ref $sender->MailMsg(\%mail_data)) {
            return $self->printInfo("head"=>"Mail Send Status","message"=>"success");
        } else {
            return $self->printError("head"=>"Mail Send Status","message"=>"Cannot send mail: $Mail::Sender::Error");
        }
    }
}
sub creatprocessId {
    my $processId=time();
	$processId.="-".int(rand(99999));
	return $processId;
}
sub is_array {
    my $self = shift;
	my ($ref) = @_;
	return 0 unless ref $ref;
    eval {
        my $a = @$ref;
    };
    if ($@=~/^Not an ARRAY reference/) {
        return 0;
    } elsif ($@) {
        return 0;
    } else {
        return 1;
    }
}
sub is_hash {
    my $self = shift;
    my $ref = @_;
    return 0 unless ref $ref;
    if ( $ref =~ /^HASH/ )
    {
        return 1;
    }
    else {
        return 0;
    }
}
sub is_nan {
    my $self = shift;
    use Scalar::Util qw(looks_like_number);
    my ($value) = @_;
    
    if( looks_like_number($value) ) {
        return 0;
    } else {
        return 1;
    }
}
sub text_validator {
    my $self = shift;
    my %hash = @_;
	if($hash{value} && $hash{value} ne '') {
		return $hash{value};
	} else {
		return 0;
	}
}
sub date_validator {
    my $self = shift;
    my %hash = @_;
	if($hash{in_pattern} && $hash{in_pattern} ne '' && $hash{out_pattern} && $hash{out_pattern} ne '' && $hash{value} && $hash{value} ne '') {
		use DateTime::Format::Strptime;
		use Date::Parse;
		my $strp = DateTime::Format::Strptime->new(pattern=>$hash{in_pattern},on_error=>'undef');
		my $dt = $strp->parse_datetime($hash{value});
		if(!$dt) {
			return 0;
		} else {
			$strp->pattern($hash{out_pattern});
			return $strp->format_datetime($dt);
		}
	} else {
		return 0;
	}
}
sub AUTOLOAD {
    my $self = shift;
	my $type = ref($self) || croak("$self is not an object");
	my $field = $AUTOLOAD;
	$field =~ s/.*://;
	my $error_log_file=$self->{error_log_file};
	my $process_id=$self->{process_id};
	my $process_time=$self->{process_time};
	my $temp='';
	my $temp1='';
	unless (exists $self->{$field}) {
		$temp="$field does not exist in object/class $type";
	}
	print STDERR "Error --> AUTOLOAD : ".$temp."\n";
	print CUSTERR "Error --> AUTOLOAD : ".$temp."\n";
	exit(1);
}
sub DESTROY {
	my $curdate3=strftime "%F %r %Z(%z)", localtime;
	print STDOUT "\n************************************  $curdate3  ***************************************** --- END\n\n\n";
	print CUSTERR "\n************************************  $curdate3  ***************************************** --- END\n\n\n";
	close(CUSTERR);
}
1;
__END__

=head1 NAME

mkdefault - Master configuration and common function file

=head1 DESCRIPTION

This file is used to set some configuration and common functions used in CMS client files.

=head1 SYNOPSIS

    use mkdefault;
    my $dbconnect=mkdefault->new(host => $dbhost, port => $dbport, username => $dbusername, password => $dbpassword);
    my $dbh=$dbconnect->getDBConnection(dbname=>$dbname);

OR

    use mkdefault;
    my $dbconnect=mkdefault->new(); * Here the host, prot, username and password will be taken from 'global.config' file
    *$CUST_GLOBAL{db}{host};
    *$CUST_GLOBAL{db}{port};
    *$CUST_GLOBAL{db}{username};
    *$CUST_GLOBAL{db}{password};
    my $dbh=$dbconnect->getDBConnection(dbname=>$dbname); * Here dbname will be taken from the config file(if any)
    *$CUST_GLOBAL{db}{name};
