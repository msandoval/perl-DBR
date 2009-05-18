package DBR::Query::ResultSet;

use strict;
use base 'DBR::Common';
use DBR::Query::Record;

sub new {
      my( $package ) = shift;
      my %params = @_;
      my $self = {
		  logger   => $params{logger},
		  dbrh     => $params{dbrh},
		  sth      => $params{sth},
		  query    => $params{query},
		  is_count => $params{is_count},
		 };

      bless( $self, $package );

      return $self->_error('sth object must be specified'   ) unless $self->{sth};
      return $self->_error('query object must be specified' ) unless $self->{query};
      return $self->_error('logger object must be specified') unless $self->{logger};
      return $self->_error('dbrh object must be specified')   unless $self->{dbrh};

      #prime the pump
      $self->{next} = *_first;

      return( $self );
}

sub count{
      my $self = shift;

      $self->_execute or return $self->_error('failed to execute');

      my $count;
      if ($self->{is_count}){
	    ($count) = $self->{sth}->fetchrow_array();
	    $self->reset();
      }else{
	    return $self->{rowcount};
      }

      return $count;
}

sub hashrefs{
      my $self = shift;

      $self->_execute or return $self->_error('failed to execute');

      my $ret = $self->{sth}->fetchall_arrayref( {} );

      $self->reset();

      return $ret;

}

sub arrayrefs{
      my $self = shift;

      $self->_execute or return $self->_error('failed to execute');

      my $ret = $self->{sth}->fetchall_arrayref();

      $self->reset();

      return $ret;
}

sub map {
      my $self = shift;
      my @fields = shift;

      $self->_execute or return $self->_error('failed to execute');

      my $ret = $self->{sth}->fetchall_hashref(@fields);

      $self->reset();

      return $ret;
}

sub _execute{
      my $self = shift;

      if( defined($self->{record_idx}) ){ # already executed

	    if ($self->{record_idx} == 0){
		  return 1; # still at zero pointer
	    }else{
		  return $self->_error('cannot execute with a nonzero record pointer');
	    };

      }
      # else Undef row pointer means we haven't executed yet

      my $sth = $self->{sth};

      $self->{rowcount} = $sth->execute();
      $self->_logDebug("ROWS: $self->{rowcount}");
      return $self->_error('failed to execute statement') unless defined($self->{rowcount});
      $self->{finished} = 0;
      $self->{record_idx} = 0;

      return 1;
}

sub next { $_[0]->{next}->( $_[0] ) }

sub _first{
      my $self = shift;

      my $record = DBR::Query::Record->new(
					   dbrh   => $self->{dbrh},
					   logger => $self->{logger},
					   query  => $self->{query},
					 ) or return $self->_error('failed to create record class');

      # need to keep this in scope, because it removes the dynamic class when DESTROY is called
      $self->{record} = $record;

      $self->{rc} = $record->class;

      $self->_execute() or return $self->_error('failed to execute');

      if ($self->{rowcount} > 200) {
	    $self->{next} = *_fetch;
	    return $self->_fetch();
      }else{
	    $self->{rows} = $self->{sth}->fetchall_arrayref();
	    $self->{sth}->finish();
	    $self->{finished} = 1;
	    $self->{next} = *_nextmem;

	    return $self->_nextmem();
      }
}

sub _nextmem{
      my $self = shift;

      my $row = $self->{rows}->[ $self->{record_idx}++ ];

      #$self->_logDebug('DID NEXTMEM');

      if ($self->{record_idx} >= $self->{rowcount}){
	    $self->{finished} = 1;
	    $self->{next} = *reset;
      }

      return bless($row,$self->{rc});
}


sub _fetch{
      my $self = shift;

      my $row  = $self->{sth}->fetchrow_arrayref();

      $self->{record_idx}++;

      #$self->_logDebug('DID FETCH');
      if (!$row){
	    $self->{finished} = 1;
	    $self->reset;
      }

      return bless($row,$self->{rc});
}

sub reset{
      my $self = shift;
      $self->_logDebug('DID RESET');
      $self->{record_idx} = undef;
      $self->{finished} = $self->{sth}->finish();

      $self->{next} = *_first;
      return undef;
}

sub DESTROY{
      my $self = shift;

      $self->{finished} || $self->{sth}->finish();

      return 1;
}

1;
