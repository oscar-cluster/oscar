c
c	$Id: f77hello.f,v 1.1 2002/10/31 00:01:19 mchasal Exp $
c
c	$COPYRIGHT$
c
	program hello
	include 'mpif.h'
	integer rank
	integer size

	call MPI_INIT(ierror)
	call MPI_COMM_SIZE(MPI_COMM_WORLD, size, ierror)
	call MPI_COMM_RANK(MPI_COMM_WORLD, rank, ierror)

	print *, 'Hello World! I am ', rank, ' of ', size

	call MPI_FINALIZE(ierror)
	stop
	end
