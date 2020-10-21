(*
 *  CS164
 *
 *  Programming Assignment 1
 *  Implementation of a simple stack machine.
 *
 *  The implementation uses a modified version of list.cl 
 *  provided in the examples.
 *	
 *)

class Stack inherits IO {

	print_list(l : List) : Object {
      	if l.isNil() 
      		then "continue"
        else {
			out_string(l.head());
			out_string("\n");
			print_list(l.tail());
		}
      	fi
   };

	contents : List <- new List;
	op1 : String;
	op2 : String;

	push(i : String) : Object {
		contents <- contents.cons(i)
	};

	pop() : String {
		(let top : String <- contents.head() in {
			contents <- contents.tail();
			top;
		})
	};

	display() : Object {
		print_list(contents)
	};

	getOperands() : Object {
		{
			pop(); -- We don't need the operator anymore
			op1 <- pop();
			op2 <- pop();
		}
		
	};

	evaluate() : Object {
		if contents.isNil() then "continue"
		else (let top : String <- contents.head() in
			if top  = "+" then (let result : String in {
				getOperands();
				result <- (new A2I).i2a((new A2I).a2i(op1) + (new A2I).a2i(op2));
				push(result);
			})
			else if top = "s" then {
				getOperands();
				push(op1);
				push(op2);
			}
			else "continue"
			fi fi
		)
		fi
	};

	getCommands() : Object {
		(let command : String, stop : Bool <- false in {
			while stop = false loop {
				out_string(">");
				command <- in_string();
				if command = "x" then stop <- true
				else if command = "d" then display()
				else if command = "e" then evaluate()
				else push(command)
				fi fi fi;
			}
			pool;		
		})
	};
};

class Main inherits IO {

   	main() : Object {
   		(let stack : Stack in {
   			stack <- new Stack;
   			stack.getCommands();
   		})	
   	};

};