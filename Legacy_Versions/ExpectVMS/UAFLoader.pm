package UAFLoader;
use vars qw(@ISA @EXPORT $VERSION);
use Pg;
@ISA=qw(Exporter);
@EXPORT=qw(LoadRecord Organize ParseRecord trim clean);
$VERSION=5.00;

sub new
{
        my $caller=shift;
        my $ref={};
        bless $ref,$caller;
        return $ref;
}

sub LoadRecord
{
        ####    get the parameters that we passed to
        ####    the function
    local ($s,*tablecols, *ParsedRecord,*conn, *table,*timestamp)=@_;

        ####    this will let us know if there is a
        ####    difference between the two records
    my $flag=0;
        ####    test to see if it has a null
        ####    uniqe key
    if($ParsedRecord[0] ne "")
    {
        @ParsedRecord=trim(@ParsedRecord);
            ####    Start generating the querys. this
            ####    first one will see if there is
            ####    already a listing in the
            ####    database for the given username
        my $query="SELECT * FROM $table WHERE $tablecols[0]=".
            "'$ParsedRecord[0]';";
            ####    execute that last query
        my $resultset=$conn->exec($query);
            ####    if there are errors report it to the
            ####    screen for now
        print (($resultset->resultStatus eq PGRES_TUPLES_OK)?
            "":"$query  caused".$conn->errorMessage."\n\n");

            ####    if there are no records with that
            ####    username then we will want to
            ####    insert a new one
        if($resultset->ntuples==0)
        {
            @ParsedRecord=clean(@ParsedRecord);
                ####    generate an insert statement
            $query= "INSERT INTO $table(". join(',',@tablecols).
                    ", lastupdated".
                    ") values('". join ("','",@ParsedRecord).
                    "','$timestamp');";
                ####    execute the command and check for errs
            $resultset=$conn->exec($query) or print "Insert Failed:$!";
            print (($resultset->resultStatus eq PGRES_COMMAND_OK)?
                "":"$query  caused ".$conn->errorMessage."\n\n");
        }
            ####    If there is a record with the same username
            ####    we want to check if the parts of the record
            ####    are identical. If they are ignore it, otherwise
            ####    we want to update the record with the new
            ####    information
        elsif($resultset->ntuples==1)
        {
                ####    fetch the row that we selected above
            my @row=$resultset->fetchrow;

                ####    as long as there are records
                ####    check to see if they are the same
            for(my $i=0;$i<@ParsedRecord;$i++)
            {
                    ####    if they are different then
                    ####    we want to set the flag to
                    ####    true so we can update.
                if($ParsedRecord[$i] ne $row[$i])
                {
                    $flag=1;
                }
            }
        }
            ####    If there is more than one tuple then we will
            ####    write an error message.
        elsif($resultset->ntuples>1)
        {
            print "Multiple entrys for $ParsedRecord[0]!\n\n";
        }
            ####    If the flag is set to true we will create an
            ####    update statement for this record
        if($flag)
        {
            @ParsedRecord=clean(@ParsedRecord);
                ####    Start off the update
            $query="UPDATE $table SET ";
                ####    Join the column names and the
                ####    new info.
            for($i=0;$i<@tablecols;$i++)
            {
                $insert[$i]= join("='",$tablecols[$i],
                        $ParsedRecord[$i]);
            }
                $insert[$i]="lastupdated='$timestamp";
                ####    complete by joining the new array
                ####    with commas.
            $query .= join("',",@insert)."' WHERE ".
                "username='$ParsedRecord[0]';";
                ####    execute and catch errors.
            $resultset=$conn->exec($query);
            print (($resultset->resultStatus eq PGRES_COMMAND_OK)?
                "":"$query  caused".$conn->errorMessage."\n\n");
        }
                $query="UPDATE $table SET lastseen='$timestamp'".
                       " WHERE username='$ParsedRecord[0]';";
                $resultset=$conn->exec($query);
                print (($resultset->resultStatus eq PGRES_COMMAND_OK)?
                        "":"$query  caused".$conn->errorMessage."\n\n");

    }
}


sub Organize
{
        ####    this function takes a hash and an
        ####    array of desired columns.
    local ($s,*info, *columns)=@_;
        ####    make a local array
    undef my @temp;
    foreach $c(@columns)
    {
            ####    for each elment in the array
            ####    push the info in the hash into
            ####    temp
        push @temp, $info{$c};
    }
        ####    return the array.
    return @temp;
}

sub ParseRecord
{
        ####    local hash to hold our info
    undef my %info;
        ####    incrimentor
    my $i=0;
        ####    get the array into an new one
    my (@records)= @_;
        ####    while there are lines...
    for(@records)
    {
            ####    if the line begins with one of our
            ####    special cases then we will execute
            ####    this next block
        if((/^Authorized Priv/)||(/^Default Priv/)||(/^Identifiers held/))
        {
                ####    if it is the identifiers
                ####    we want to give a generic name
                ####    to the key
            if(/^Identifiers held/)
            {
                $values[0]="Identifiers:   ";
            }
                ####    otherwise we will just
                ####    make the key whats in the UAF
            else
            {
                $values[0]=trim($_)."  ";
            }
                ####    for everything concat secondary
                ####    lines onto the key
            for($j=1;($records[$i+$j] =~ /^\s+/);$j++)
            {
                @vars= ($records[$i+$j] =~ /\S+/g);
                $values[0] .= join (',', @vars);
            }
        }
            ####    if its the last login field then we
            ####    split a little differently.
        elsif(/^Last Login/)
        {
            @values=split /:s+/;
        }
            ####    Otherwise do some funky regexp
            ####    to break up the other key/ values
        else
        {
            @values=/(.*?:\s+.*?(?:\s{2,}|\n))/g;
        }

            ####    trim whitespace
        @values=trim(@values);
            ####    while there are values in the array we will loop
        for(@values)
        {
                ####    split an trim the tokens into their key value pairs
            @keypairs=trim(@keypairs=split /:\s+/);
                ####    make the entry into the hash table.
            $info{$keypairs[0]}=$keypairs[1];
        }
        $i++;
    }
    return (\%info);
}

sub trim
{
        my @out=@_;
        for(@out)
        {
                s/^\s+//;s/\s+$//;
        }
        return wantarray ? @out:$out[0];
}

sub clean{
    my @out=@_;
    for(@out){
        s/'/''/g;
    }
    return wantarray ? @out:$out[0];
}

1;
