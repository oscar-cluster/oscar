
static char rcsid[] =
	"$Id: master1.c,v 1.2 2002/10/31 19:22:17 jsquyres Exp $";

/*
 *         PVM version 3.4:  Parallel Virtual Machine System
 *               University of Tennessee, Knoxville TN.
 *           Oak Ridge National Laboratory, Oak Ridge TN.
 *                   Emory University, Atlanta GA.
 *      Authors:  J. J. Dongarra, G. E. Fagg, M. Fischer
 *          G. A. Geist, J. A. Kohl, R. J. Manchek, P. Mucci,
 *         P. M. Papadopoulos, S. L. Scott, and V. S. Sunderam
 *                   (C) 1997 All Rights Reserved
 *
 *                              NOTICE
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose and without fee is hereby granted
 * provided that the above copyright notice appear in all copies and
 * that both the copyright notice and this permission notice appear in
 * supporting documentation.
 *
 * Neither the Institutions (Emory University, Oak Ridge National
 * Laboratory, and University of Tennessee) nor the Authors make any
 * representations about the suitability of this software for any
 * purpose.  This software is provided ``as is'' without express or
 * implied warranty.
 *
 * PVM version 3 was funded in part by the U.S. Department of Energy,
 * the National Science Foundation and the State of Tennessee.
 *
 * Copyright (c) 2002 The Trustees of Indiana University.  
 *                    All rights reserved.
 */

#include <stdio.h>
#include <stdlib.h>
#include "pvm3.h"
#define SLAVENAME "slave1"

main()
{
    int mytid;                  /* my task id */
	int tids[32];				/* slave task ids */
    int n, nproc, numt, i, who, msgtype, nhost, narch;
    float data[100], result[32];
    struct pvmhostinfo *hostp;
    int successful = 1;
    float expected;

    /* enroll in pvm */
    mytid = pvm_mytid();

    /* Set number of slaves to start */
    pvm_config( &nhost, &narch, &hostp );
    nproc = nhost * 3;
    if( nproc > 32 ) nproc = 32 ;
	printf("Spawning %d worker tasks ... " , nproc);

    /* start up slave tasks */
    numt=pvm_spawn(SLAVENAME, (char**)0, 0, "", nproc, tids);
    if( numt < nproc ){
       printf("\n Trouble spawning slaves. Aborting. Error codes are:\n");
       for( i=numt ; i<nproc ; i++ ) {
          printf("TID %d %d\n",i,tids[i]);
       }
       for( i=0 ; i<numt ; i++ ){
          pvm_kill( tids[i] );
       }
       pvm_exit();
       exit(1);
    }
    printf("Done\n");

    /* Begin User Program */
    n = 100;
    /* initialize_data( data, n ); */
    for( i=0 ; i<n ; i++ ){
       data[i] = 1.0;
    }

    /* Broadcast initial data to slave tasks */
	pvm_initsend(PvmDataDefault);
	pvm_pkint(&nproc, 1, 1);
	pvm_pkint(tids, nproc, 1);
	pvm_pkint(&n, 1, 1);
	pvm_pkfloat(data, n, 1);
    pvm_mcast(tids, nproc, 0);

    /* Wait for results from slaves */
    msgtype = 5;
    for( i=0 ; i<nproc ; i++ ){
       pvm_recv( -1, msgtype );
       pvm_upkint( &who, 1, 1 );
       pvm_upkfloat( &result[who], 1, 1 );
       if (who == 0)
	 expected = (nproc - 1) * 100.0;
       else
	 expected = (2 * who - 1) * 100.0;
       printf("I got %f from %d; (expected %f)\n",result[who],who,expected);
       if (result[who] != expected)
	 successful = 0;		
    }
    if (successful)
      printf("SUCCESSFUL\n");
    /* Program Finished exit PVM before stopping */
    pvm_exit();
    exit(0);
}

