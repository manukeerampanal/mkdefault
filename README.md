# mkdefault
Some Common functions used in my perl programs

This file is used to set some configuration and common functions used in CMS client files.

    use configuration;
    my $dbconnect=configuration->new(host => $dbhostname, port => $dbport, username => $dbusername, password => $dbpassword);
    my $dbh=$dbconnect->getDBConnection(dbname=>$dbname);

OR

    use configuration;
    my $dbconnect=configuration->new(); * Here the host, prot, username and password will be taken from mt_requests.config file
    *$CUST_GLOBAL{db}{hostname};
    *$CUST_GLOBAL{db}{port};
    *$CUST_GLOBAL{db}{username};
    *$CUST_GLOBAL{db}{password};
    my $dbh=$dbconnect->getDBConnection(dbname=>$dbname); * Here dbname will be taken from 'global.config' file
    *$CUST_GLOBAL{db}{name};
