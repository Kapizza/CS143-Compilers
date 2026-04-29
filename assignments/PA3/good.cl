-- good.cl: exercises every legal COOL grammar construct

-- Attributes with and without initializers; methods with various formals
class Animal {
    name : String <- "unknown";
    age  : Int;
    alive : Bool <- true;

    -- no-arg method, simple body
    sound() : String { "..." };

    -- method with one formal
    set_name(n : String) : SELF_TYPE {
        { name <- n; self; }
    };

    -- method using if/then/else
    describe(verbose : Bool) : String {
        if verbose
        then name.concat(" age ").concat(age.type_name())
        else name
        fi
    };
};

-- Inheritance
class Dog inherits Animal {
    tricks : Int <- 0;

    sound() : String { "woof" };

    -- while loop
    learn(n : Int) : SELF_TYPE {
        {
            while 0 < n loop
                { tricks <- tricks + 1; n <- n - 1; }
            pool;
            self;
        }
    };

    -- arithmetic and comparisons in one expression
    better_than(other : Dog) : Bool {
        other.get_tricks() < tricks
    };

    get_tricks() : Int { tricks };
};

-- Case expression + let + block + dispatch
class Main inherits IO {
    main() : Object {
        let d : Dog <- new Dog,
            s : String <- "test",
            i : Int <- 0
        in {
            -- self dispatch
            out_string("start\n");

            -- assignment
            i <- 42;

            -- dynamic dispatch
            d.set_name("Rex");
            d.learn(3);

            -- static dispatch
            d@Dog.sound();

            -- nested let
            let x : Int <- i + 1 in
                let y : Int <- x * 2 in
                    out_int(y);

            -- case expression
            case d of
                a : Dog    => out_string(a.sound());
                b : Animal => out_string(b.sound());
                c : Object => out_string("object\n");
            esac;

            -- isvoid
            if isvoid d then out_string("void\n") else out_string("ok\n") fi;

            -- not / complement
            if not (i = 0) then out_int(i) else out_int(0) fi;

            -- integer complement
            out_int(~i);

            -- comparisons
            if i < 100 then out_string("small\n") else out_string("big\n") fi;
            if i <= 42  then out_string("le\n")    else out_string("gt\n")  fi;

            -- new
            let a2 : Animal <- new Animal in a2.sound();

            -- block as expression value
            i <- { out_string("block\n"); 99; };

            out_string("done\n");
        }
    };
};
