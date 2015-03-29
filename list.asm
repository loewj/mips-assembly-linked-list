#  Linked structures in assembler       D. Hemmendinger  24 January 2009
#  Linked structures in assembler       J. Rieffel 15 February 2011
#  New, insert, and print               J. Loew March 2015
# (removed dependance on in-line constant definitions)
#  This program builds a heap as a singly-linked list of nodes that
#  are then used to build a singly-linked list of numbers.

## System calls
PR_INT = 1
PR_STR = 4

## Node structure
NEXT     = 0    # offset to next pointer
DATA     = 4    # offset to data
DATASIZE = 4
NODESIZE = 8    # DATA + DATASIZE - bytes per node
NUMNODES = 15
HEAPSIZE = 120  # NODESIZE*NUMNODES
NIL      = 0    # for null pointer

        .data
input: .word 5, 4, 3, 2, 1 # you add more numbers here  (no more than NUMNODES)
inp_end:
INSIZE = 1 #(inp_end - input)/4    # number of input array elements

heap:   .space  HEAPSIZE           # storage for nodes
spce:   .asciiz "  "
nofree: .asciiz "Out of free nodes; terminating program\n"

        .align 2
        .text
main:   addi $sp, $sp, -4
        sw $ra, 0($sp)
        li $s7, NIL             # global variable holding the NIL value
        la $a0, heap            # pass the heap address to mknodes
        li $a1, HEAPSIZE	      # and its size
        li $a2, NODESIZE 	      # and the size of a node
        jal mknodes

	# initially our linked list will be empty (nil)
	# lw, $a0, input
	# li, $a1, nil
	# move $a2, $v0  presuming $v0 contains a pointer to free after mknodes is
  # called

  la $s0, input
  la $s1, inp_end

  # load into $a0 the first index of the array for insertion
  lw $a0, 0($s0)
  move $a2, $v0
  move $a1, $s7

  jal insert                   # try to insert the first value

  ##=====================
  # Loop to try and insert all values in "input"

        add $s2, $0, 1         # initialize the counter
loop:   sll $s3, $s2, 2
        add $s3, $s0, $s3
        lw $a0, 0($s3)
        move $a2, $v1
        move $a1, $v0
        beq $a0, $s7, done
        jal insert
        addi $s2, $s2, 1       # increment the counter
        j loop


  ##=====================

done:   move $a0, $v0
        jal print
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra

# mknodes takes a heap address in a0, its byte-size in a1, and node size in a2
#  and partitions it into a singly-linked list of nodesize
# (NODESIZE-byte) nodes, pointed to by free.
# NOTE:  the list is built with free pointing to the last node in the
#    heap area, which points to the previous one, etc.  The reason for
#    this construction is to be sure that you get nodes by calling
#    "new" rather than by rebuilding the heap yourself!
# Register usage:
# inputs:
# $a0 contains a pointer to the heap
# $a1 contains the heapsize
# $a2 contains the nodesize

# used registers
# $t0: pointer to block that will become a node
# $t1: pointer to previous block (will become next node)

# $v0: points to the first free node in the heap

mknodes:
        add $t0, $a0, $a1       # t0 starts by pointing to the last
        sub $t0, $t0, $a2       # node-sized block in the heap
        move  $v0, $t0          # set output v0 to point to that first node
mkloop: sub $t1, $t0, $a2       # t1 points to previous node-sized block
        sw  $t1, NEXT($t0)      # link the t0->node to point to t1 node
        move $t0, $t1           # back up t0 by one node
        bne $t0, $a0, mkloop    # repeat if not at heap-start
        sw $s7, NEXT($t1)       # ground node (first block in heap)
        jr $ra

# Removes a node from free (passed in via $a0), returning a pointer to the node
# in $v0,
# and a pointer to the new free in $v1
#  ( returns NIL if none available)
# inputs:
#    $a0: points to the first "free" node in the heap
# outputs:
#    $v0: the node we have "created" (pulled off the stack from free)
#    $v1: the new value of free (we don't want to clobber $a0 when we change
#         free, right? right?)

new:    bne $a0, NIL, isFree    # check if
        move $v0, $s7           # $v0: NIl
        move $v1, $s7           # $v1: NIL
        j newdone
isFree: move $v0, $a0           # $v0: new node address
        lw $v1, NEXT($a0)       # $t0: address of next node (must be free)
        sw $v0, NEXT($v0)
newdone:jr $ra


# insert behaves as described in the lab text
# inputs:
#	 $a0: should contain N
#	 $a1: should contain a pointer to our linked list
#	 $a2: should contain a pointer to free
#
# outputs:
# 	$v0 should contain the new pointer to our linked list
#	  $v1 should contain the new pointer to free

insert: addi $sp, $sp, -8       # allocate space on the stack
        sw $ra, 0($sp)
        sw $a0, 4($sp)          # push $a0 to stack
        move $a0, $a2           # move $a2 into $a0
        jal new                 # $v0: new node
        lw $a0, 4($sp)          # retore $a0 from stack
        beq $v0, $s7, nonode    # now, check to see if next is null
        move $t0, $v0           # $t0: new node
        sw $a0, DATA($t0)       # new node has N
        beq $a1, $s7, body      # test list pointer == NIL
        lw $t1, DATA($a1)       # compare N to LL data
        ble $t1, $a0, else      # N < lstptr.data
body:   sw $a1, NEXT($t0)       # tmpptr.next = lstptr
        move $a1, $t0           # lstptr = tmpptr
        j insdone               # done
else:   move $t2, $a1           # $t2: currptr
while:  lw $t3, NEXT($t2)       # $t3: currptr.next
        beq $t3, $s7, ewhile    # if currptr.next = NIL, branch
        lw $t4, DATA($t3)       # $t4: currptr.next.data
        blt $a0, $t4, ewhile    # if N < currptr.next.data, branch
        move $t2, $t3           #
        j while                 # loop
ewhile: lw $t5, NEXT($t2)       # $t5: curptr.next
        sw $t5, NEXT($t0)       # $t6: currptr.next
        sw $t0, NEXT($t2)       # tmp.next = currptr.next
insdone:move $v0, $a1           # return the LL
        lw $ra, 0($sp)          # pop ra off stack
        addi $sp, $sp, 8        # restore stack to state
        jr $ra                  # return to caller

nonode: move $t0, $a0
        move $t1, $v0

        li $v0, PR_STR          # load in the string
        la $a0, nofree          # load in the message
        syscall

        move $a0, $t0
        move $v0, $t1
        j insdone

## print out the values in the linked list
## $a0: pointer to the LL

print:  move $t0, $a0           # $t0: our LL
        j ptest                 # is it null?

ploop:  lw $t1, DATA($t0)

        move $a0, $t1
        li $v0, PR_INT
        syscall

        li $v0, PR_STR
        la $a0, spce
        syscall

        lw $t0, NEXT($t0)

ptest:  bne $t0, $s7, ploop
        jr $ra
