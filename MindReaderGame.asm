.data
	.eqv CARD_SIZE 32
	.eqv CARD_WIDTH 8
	.eqv TOTAL_VALUES 64
	currentCard: .space 128
	
	possibleValues: .space 256
	nonPossValues: .space 256
	
	cardPossValues: .space 128
	nonCardPossValues: .space 128
	
	space: .asciiz " "
	newLine: .asciiz "\n"
	startGameMsg: .asciiz "\nChoose a a number 1 - 64 and the cards will guess it! Would you like to begin? (y/n)\n"
	askOnCard: .asciiz "\nIs the number you chose on this card? (y/n)\n"
	answerMsg: .asciiz "The number you were thinking of was: "
	askPlayAgain: .asciiz "\n\nWould you like to play again? (y/n)\n"
	invalid: .asciiz "\nYour input was invalid. Please respond with (y) or (n)\n"
	exitMsg: .asciiz "\nExiting game"
	
	c1Title: .asciiz "\n       CARD ONE       \n"
	c2Title: .asciiz "\n       CARD TWO       \n"
	c3Title: .asciiz "\n      CARD THREE       \n"
	c4Title: .asciiz "\n       CARD FOUR       \n"
	c5Title: .asciiz "\n       CARD FIVE       \n"
	c6Title: .asciiz "\n       CARD SIX       \n"
	
.text
main:
# 	ask the user to pick a number and start the game
	li $v0, 4
	la $a0, startGameMsg			# print startGameMsg
	syscall
	
	jal processUserChoice			# get user input to begin
	beq $v0, $zero, Exit
	
	li $v0, 4
	la $a0, newLine
	syscall
	
gameSetUp:
	li $s0, TOTAL_VALUES			# $s0 = possibleValues.length = TOTAL_VALUES
	
	li $s1, 1				# $s1 = cardNumber = 1
	
	la $a0, possibleValues
	add $a1, $zero, $s0
	jal fillArray				# fill possibleValues[] with numbers 1 - TOTAL_VALUES
	
gameLoop:
#	generate a card
#		split possibleValues[] in half, cardPossValues[] go on the card, nonCardPossValues don't go on the card
	la $a0, possibleValues
	add $a1, $zero, $s0
	la $a2, cardPossValues
	la $a3, nonCardPossValues
	jal randomlySplitArray
	
#		fill cardArray with cardPossValues[]. If that isn't enough to fill it, then pull numbers from nonPossValues[]
	la $a0, currentCard
	la $a1, cardPossValues
	add $a2, $zero, $s0
	la $a3, nonPossValues
	jal fillNewCard
	
#		sort cardArray[]
	la $a0, currentCard
	jal sortArray


#	display the card
	add $a0, $zero, $s1
	jal displayCardTitle
	
	la $a0, currentCard
	jal displayCard
	
	addi $s1, $s1, 1			# cardNumber++

#	possValuesLength = possValuesLength / 2
	srl $s0, $s0, 1
	
#	ask the user if their number is on the card
	li $v0, 4
	la $a0, askOnCard
	syscall
	
# 	get response from the user
	jal processUserChoice

#		if yes, set possibleValues[] = to cardPossValues[]; add the values of nonCardPossValues[] to the end of nonPossValues[]	
	beq $v0, $zero, notOnCard

	la $a0, possibleValues
	la $a1, cardPossValues
	add $a2, $zero, $s0
	jal copyArray
	
	la $a0, nonPossValues
	li $a1, TOTAL_VALUES
	sub $a1, $a1, $s0
	sub $a1, $a1, $s0			# $a1 = nonPossValues.length = TOTAL_VALUES - (2 * possValuesLength)
	la $a2, nonCardPossValues
	add $a3, $zero, $s0
	jal concatArray
	
	j afterResponseGiven
	
#		if no, set possibleValues[] = to nonCardPossValues[]; add the values of cardPossValues[] to the end of nonPossValues[]
notOnCard:
	la $a0, possibleValues
	la $a1, nonCardPossValues
	add $a2, $zero, $s0
	jal copyArray

	la $a0, nonPossValues
	li $a1, TOTAL_VALUES
	sub $a1, $a1, $s0
	sub $a1, $a1, $s0			# $a1 = nonPossValues.length = TOTAL_VALUES - (2 * possValuesLength)
	la $a2, cardPossValues
	add $a3, $zero, $s0
	jal concatArray

afterResponseGiven:

	li $v0, 4
	la $a0, newLine				# print newLine
	syscall
	
# loop until possValueLength == 1
	slti $t0, $s0, 2			# if(possValuesLength < 2)
	beq $t0, $zero, gameLoop		#	continue game

#	Display the one remaining possible value to the user as it must be their value
	li $v0, 4
	la $a0, answerMsg
	syscall
	
	li $v0, 1
	la $t0, possibleValues
	lw $a0, ($t0)
	syscall
	
#	ask the user if they want to play again. loop the whole game if they do, otherwise exit the game
	li $v0, 4
	la $a0, askPlayAgain
	syscall
	
	jal processUserChoice
	
	bne $v0, $zero, main
	
Exit:
	li $v0, 4				# print exit message
	la $a0, exitMsg
	syscall
	
	li $v0, 10				# exit the program
	syscall


randomlySplitArray:
#	Splits an array into two arrays that are half the size, distributing the values of the original array between the two randomly
# $a0 = splitArray
# $a1 = splitArray.length
# $a2 = arrayHalfOne
# $a3 = arrayHalfTwo
	add $t0, $a0, $zero			# $t0 = splitArray[]
	add $t1, $a2, $zero			# $t1 = arrayHalfOne[]
	add $t2, $a3, $zero			# $t2 = arrayHalfTwo[]

	add $t3, $zero, $zero			# $t3 = i = splitArray index counter
	add $t4, $zero, $zero			# $t4 = j = arrayHalfOne index counter
	add $t5, $zero, $zero			# $t5 = k = arrayHalfTwo index counter

	srl $t6, $a1, 1				# $t6 = splitArray.length / 2

RSALoop:
	sll $t9, $t3, 2				# $t9 = i * 4
	add $t7, $t9, $t0			# $t7 = &splitArray[i]
	lw $t7, ($t7)				# $t7 = splitArray[i]

	li $v0, 42				# get random number, either 0 or 1
	li $a1, 2
	syscall
						# random number is stored in $a0
	beq $a0, $zero, addToCard		# if($a0 == 0) add splitArray[i] to arrayHalfOne[]
						# else add splitArray[i] to arrayHalfTwo[]
	sll $t9, $t5, 2
	add $t9, $t9, $t2
	sw $t7, ($t9)				# arrayHalfTwo[k] = splitArray[i]
	
	addi $t5, $t5, 1			# k++
	j continueRSALoop
	
addToCard:
	sll $t9, $t4, 2
	add $t9, $t9, $t1
	sw $t7, ($t9)				# arrayHalfOne[j] = splitArray[i]
	
	addi $t4, $t4, 1			# j++
	
continueRSALoop:
	addi $t3, $t3, 1			# i++
	slt $t7, $t4, $t6
	slt $t8, $t5, $t6
	and $t9, $t7, $t8
						# if((j < splitArray.length / 2) && (k < splitArray.length / 2))
	bne $t9, $zero, RSALoop			# 	continue the loop
# end RSALoop

	beq $t7, $zero, fillNonCard		# if(j < splitArray.length / 2)

	sll $t8, $t4, 2				# fill arrayHalfOne[] with the remainder of splitArray[]
	add $t9, $t1, $t8
	
	j RSALoop2
fillNonCard:					# else
	sll $t8, $t5, 2				# fill arrayHalfTwo[] with the remainder of splitArray[]
	add $t9, $t2, $t8

						# $t9 = the array that needs to be filled
RSALoop2:
	sll $t7, $t3, 2				# $t7 = i * 4
	add $t8, $t7, $t0			# $t8 = &splitArray[i]
	lw $t8, ($t8)				# $t8 = splitArray[i]
	sw $t8, ($t9)				# store splitArray[i] at the end of the array
	
	addi $t3, $t3, 1			# i++
	addi $t9, $t9, 4			# $t9 array index ++
	
	sll $t7, $t6, 1				# $t7 = splitArray.length
	slt $t8, $t3, $t7			# if(i < splitArray.length)
	bne $t8, $zero, RSALoop2		# 	continue loop
# end RSALoop2
	
	jr $ra
# end randomlySplitArray



fillNewCard:
#	Fills a card with the half of the possible values. If this is not enough to fill the card, it fills the rest of the card with random non-possible values
# $a0 = cardArray[]
# $a1 = cardPossValues[]
# $a2 = possValuesLength
# $a3 = nonPossValues[]

	add $t0, $a0, $zero			# $t0 = cardArray[]
	add $t1, $a1, $zero			# $t1 = cardPossValues[]
	add $t2, $a3, $zero			# $t2 = nonPossValues[]
	
	srl $t3, $a2, 1				# $t3 = cardPossValues.length
	
	add $t4, $zero, $zero			# $t4 = i = array index counter
	add $t9, $zero, $zero			# $t9 = n = stack counter
	
FNCLoop:
	sll $t5, $t4, 2
	add $t6, $t5, $t1
	lw $t6, ($t6)				# $t5 = cardPossValues[i]
	
	add $t7, $t0, $t5
	sw $t6, ($t7)				# cardArray[i] = cardPossValues[i]
	
	addi $t4, $t4, 1			# i++
	
	slt $t5, $t4, $t3			# if(i < cardPossValues.length)
	bne $t5, $zero, FNCLoop			#	continue FNCLoop
# end FNCLoop

	slti $t5, $t3, CARD_SIZE		# if(cardPossValues.length == CARD_SIZE)
	beq $t5, $zero, FNCExit			#	skip to fillNewCardExit
	
	add $t5, $zero, $zero			# $t5 = j = nonPossValues index counter
	
	sll $t6, $t3, 1
	addi $t7, $zero, TOTAL_VALUES
	sub $t8, $t7, $t6			# $t8 = 64 - 2 * cardPossValues.length = nonPossValues.length
FNCLoop2:
	sll $t6, $t5, 2
	add $t7, $t6, $t2
	lw $t7, ($t7)				# $t6 = nonPossValues[j]
	
	li $v0, 42				# get random number, either 0 or 1
	li $a1, 2
	syscall
						# random number is stored in $a0
	beq $a0, $zero, FNCSkipNum		# if($a0 == 1) add nonPossValues[j] to the card
	
	sll $t6, $t4, 2			
	add $t6, $t6, $t0
	sw $t7, ($t6)				# cardArray[i] = nonPossValues[j]
	
	addi $t4, $t4, 1			# i++
	j FNCLoop2Cont
FNCSkipNum:					# else, if($a0 == 0) place nonPossValues[j] on the stack in case it's needed at the end of the loop
	addi $sp, $sp, -4
	sw $t7, ($sp)
	
	addi $t9, $t9, 4			# n++
	
FNCLoop2Cont:
	addi $t5, $t5, 1			# j++
	
	slt $t6, $t5, $t8			# if(j < nonPossValues.length)
	slti $t7, $t4, CARD_SIZE		# if(i < CARD_SIZE)
	and $t6, $t6, $t7			# if((j < nonPossValues.length) && (i < CARD_SIZE))
	bne $t6, $zero, FNCLoop2		#	continue loop
	
	beq $t7, $zero, FNCExit			# if(i == CARD_SIZE)
# end FNCLoop2					#	go to FNCExit
	
FNCLoop3:					# else, pull values off of the stack until cardArray[] is full
	lw $t6, ($sp)				# get value from the stack (one of the values from nonPossValues that isn't already in cardArray)
	addi $sp, $sp, 4
	addi $t9, $t9, -4			# n--
	
	sll $t7, $t4, 2
	add $t7, $t7, $t0
	sw $t6, ($t7)				# cardArray[i] = top value from the stack
	
	addi $t4, $t4, 1			# i++
	
	slti $t7, $t4, CARD_SIZE		# if(i < CARD_SIZE)
	bne $t7, $zero, FNCLoop3			#	continue loop
# end FNCLoop3

FNCExit:
	add $sp, $sp, $t9			# remove leftover values from the stack
	
	jr $ra
# end fillNewCard


sortArray:
#	Sorts an array into ascending order
# $a0 = Array[]
	add $t0, $zero, $zero			# $t0 = i = 0
SALoop:
	add $t1, $zero, $t0			# $s0 = minIndex = i
	sll $t2, $t0, 2
	add $t9, $a0, $t2			# $t9 = &Array[i]
	lw $t2, ($t9)				# $s1 = minValue = Array[i]
	
	addi $t3, $t0, 1			# $t1 = j = i + 1
SAFindLowest:
	sll $t4, $t3, 2
	add $t4, $a0, $t4
	lw $t4, ($t4)				# $t4 = Array[j]
	
	slt $t5, $t4, $t2			# if(Array[j] < minValue)
	beq $t5, $zero, SANotMinVal
	
	add $t2, $zero, $t4			# minValue = Array[j]
	add $t1, $zero, $t3			# minIndex = j
	
SANotMinVal:
	addi $t3, $t3, 1			# j++
	slti $t4, $t3, CARD_SIZE		# if(j < Array.size())
	bne $t4, $zero, SAFindLowest		# 	jump to findLowest
# end findLowest loop

	lw $t3, ($t9)				# $t3 = temp = Array[i]
	sw $t2, ($t9)				# Array[i] = minValue
	
	sll $t4, $t1, 2
	add $t5, $a0, $t4
	sw $t3, ($t5)				# Array[minIndex] = temp
	
	addi $t0, $t0, 1			# i++
	addi $t2, $zero, CARD_SIZE
	addi $t2, $t2, -1
	slt $t2, $t0, $t2			# if(i < Array.size() - 1)
	bne $t2, $zero, SALoop			# 	jump to arrayLoop
# end arrayLoop

	jr $ra
# end sortArray


displayCardTitle:
#	prints the title of the card being displayed
# $a0 = cardNumber

	li $v0, 4
	
	bne $a0, 1, DCTNext1
	la $a0, c1Title
	j exitDCT
	
DCTNext1:
	bne $a0, 2, DCTNext2
	la $a0, c2Title
	j exitDCT
	
DCTNext2:
	bne $a0, 3, DCTNext3
	la $a0, c3Title
	j exitDCT
	
DCTNext3:
	bne $a0, 4, DCTNext4
	la $a0, c4Title
	j exitDCT
	
DCTNext4:
	bne $a0, 5, DCTNext5
	la $a0, c5Title
	j exitDCT
	
DCTNext5:
	la $a0, c6Title

exitDCT:
	syscall
	
	jr $ra
# end displayCardTitle


displayCard:
# 	takes a sorted array and a card name (i.e. "card one") and prints them as a card
# $a0 = array[]

	add $t9, $zero, $a0			# t9 = array

	add $t0, $zero, $zero 			# t0 = i = 0
	add $t1, $zero, $zero			# t1 = lineCounter = 0
	
DCLoop:
	sll $t3, $t0, 2
	add $t3, $t3, $t9
	lw $t4, ($t3)				# t4 = array[i]
	
	slti $t5, $t4, 10			# if(array[i] < 10) print a space before the int
	beq $t5, $zero, DCNoSpace
	
	li $v0, 4				# print a space
	la $a0, space
	syscall
DCNoSpace:
	li $v0, 1				# print array[i]
	add $a0, $t4, $zero
	syscall
	
	li $v0, 4				# print a space
	la $a0, space
	syscall
	
	addi $t0, $t0, 1			# i++
	
	addi $t1, $t1, 1			# lineCounter++
	
	slti $t3, $t1, CARD_WIDTH	
	bne $t3, $zero, DCNoNewLine		# if(lineCounter == cardWidth)
						#	print a new line
	li $v0, 4
	la $a0, newLine
	syscall
	
	add $t1, $zero, $zero			# lineCounter = 0
	
DCNoNewLine:
	slti $t3, $t0, CARD_SIZE		# if(counter < cardsize)
	bne $t3, $zero, DCLoop			# 	continue loop
# end DCLoop
	
	jr $ra
# end displayCard


copyArray:
#	Copies the contents of fromArray[] to toArray[]
# $a0 = toArray[]
# $a1 = fromArray[]
# $a2 = array length

	add $t0, $zero, $zero			# $t0 = i = 0
	
copyLoop:
	sll $t1, $t0, 2
	add $t2, $t1, $a1
	lw $t3, ($t2)				# $t3 = fromArray[i]
	add $t4, $t1, $a0
	sw $t3, ($t4)				# toArray[i] = fromArray[i]
	
	addi $t0, $t0, 1			# i++
	
	slt $t1, $t0, $a2			# if(i < array.length())
	bne $t1, $zero, copyLoop		#	continue loop
# end copyLoop

	jr $ra
# end copyArray

concatArray:
#	concatenates fromArray to the end of toArray
# $a0 = toArray[]
# $a1 = last used index of toArray[]
# $a2 = fromArray[]
# $a3 = fromArray.length

	add $t0, $zero, $zero			# $t0 = i = 0
	add $t1, $zero, $a1			# $t1 = j = last used index of toArray[]

concatLoop:
	sll $t2, $t0, 2
	add $t2, $t2, $a2
	lw $t2, ($t2)				# $t2 = fromArray[i]
	
	sll $t3, $t1, 2
	add $t3, $t3, $a0
	sw $t2, ($t3)				# toArray[j] = fromArray[i]
	
	addi $t0, $t0, 1			# i++
	addi $t1, $t1, 1			# j++
	
	slt $t4, $t0, $a3			# if(i < fromArray.length)
	bne $t4, $zero, concatLoop		#	continue loop
# end concatLoop

	jr $ra
# end concatArray


fillArray:
#	fills an array with the values 1 - array.length
# $a0 = array[]
# $a1 = array.length

	add $t0, $zero, $zero			# $t0 = i = 0
	addi $t1, $zero, 1			# $t1 = j = 1
	
FALoop:
	add $t2, $t0, $a0
	sw $t1, ($t2)
	
	addi $t0, $t0, 4			# i++
	addi $t1, $t1, 1			# j++
	
	sle $t2, $t1, $a1
	bne $t2, $zero, FALoop
# end FALoop

	jr $ra
# end fillArray


processUserChoice:
#	takes in a user's choice, returns true if 'y', false if 'n', and asks for input again if an invalid choice is entered

	# Store syscall for read character
	li $v0, 12 
	syscall
	# Get the value from the syscall to t0
	move $t0, $v0
	# If the input was lowercase or uppercase y, branch to return true
	beq $t0, 'y', pucReturnTrue
	beq $t0, 'Y', pucReturnTrue
	# If the input was lowercase or uppercasae n, branch to return false
	beq $t0, 'n', pucReturnFalse
	beq $t0, 'N', pucReturnFalse
	# If the input was none of them, print the string for invalid input
	li $v0, 4
	la $a0, invalid
	syscall
	# Then loop back to the start of the input
	j processUserChoice

pucReturnFalse:
	# Return 0
	li $v0, 0
	jr $ra
pucReturnTrue:
	# Return 1
	li $v0, 1
	jr $ra
# end processUserChoice
