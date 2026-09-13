-- =====================================================================
-- SkillAI — MySQL schema
-- Import this file directly via phpMyAdmin (Import tab) or:
--   mysql -u root -p < database.sql
-- This file also loads the complete 250-question bank automatically.
-- =====================================================================

CREATE DATABASE IF NOT EXISTS `skillai`
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE `skillai`;

-- ---------------------------------------------------------------------
-- questions: 250 MCQs, 5 languages x 5 levels x 10 questions
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `questions` (
  `id`             INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `language`       VARCHAR(10) NOT NULL,
  `level`          TINYINT UNSIGNED NOT NULL,
  `text`           TEXT NOT NULL,
  `code`           TEXT NULL,
  `options`        JSON NOT NULL,
  `correct_index`  TINYINT UNSIGNED NOT NULL,
  `explanation`    TEXT NULL,
  `tags`           JSON NULL,
  `created_at`     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_lang_level` (`language`, `level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- attempts: one row per test taken. slots/answers/result are JSON blobs,
-- mirroring the flexible document shape used in the original design.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `attempts` (
  `id`             INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_name`      VARCHAR(40) NOT NULL DEFAULT 'Guest',
  `language`       VARCHAR(10) NOT NULL,
  `status`         ENUM('in_progress','completed') NOT NULL DEFAULT 'in_progress',
  `slots`          JSON NULL,
  `answers`        JSON NULL,
  `result`         JSON NULL,
  `unimesh_user_id` INT UNSIGNED NULL,
  `unimesh_skill_id` INT UNSIGNED NULL,
  `started_at`     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `completed_at`   DATETIME NULL,
  PRIMARY KEY (`id`),
  KEY `idx_user` (`user_name`),
  KEY `idx_language` (`language`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- Built-in 250-question bank
-- Importing this file is enough; seed.php is optional for reloading later.
-- ---------------------------------------------------------------------
DELETE FROM `questions`;

INSERT INTO `questions` (`language`,`level`,`text`,`code`,`options`,`correct_index`,`explanation`,`tags`) VALUES
('python', 1, 'Which keyword is used to define a function in Python?', '', '["func","def","function","define"]', 1, 'Python functions are declared with the def keyword.', '["syntax","functions"]'),
('python', 1, 'What is the type of the value 3.14 in Python?', '', '["int","str","float","bool"]', 2, 'A decimal numeric literal such as 3.14 is a float.', '["types"]'),
('python', 1, 'Which function is commonly used to read keyboard input in Python?', '', '["scan()","read()","input()","get()"]', 2, 'input() reads a line from standard input.', '["io"]'),
('python', 1, 'Which symbol starts a single-line comment in Python?', '', '["//","#","/*","--"]', 1, 'Python uses # for single-line comments.', '["syntax"]'),
('python', 1, 'What does print() do?', '', '["Reads input","Displays output","Creates a variable","Ends the program"]', 1, 'print() writes values to standard output.', '["io"]'),
('python', 1, 'Which of these is a valid Python variable name?', '', '["2name","first-name","first_name","class"]', 2, 'first_name is a valid identifier; identifiers cannot begin with digits or contain hyphens, and class is reserved.', '["variables"]'),
('python', 1, 'What is the result of 7 // 2 in Python?', '', '["3","3.5","4","1"]', 0, '// performs floor division, so 7 // 2 is 3.', '["operators"]'),
('python', 1, 'Which value represents Boolean false in Python?', '', '["false","FALSE","False","0.0f"]', 2, 'Python''s Boolean literals are True and False.', '["types","boolean"]'),
('python', 1, 'What is the result of len(''Python'')?', '', '["5","6","7","Error"]', 1, 'The string ''Python'' contains six characters.', '["strings"]'),
('python', 1, 'Which operator is used for exponentiation in Python?', '', '["^","**","pow^","^^"]', 1, 'Python uses ** for exponentiation.', '["operators"]'),
('python', 2, 'What is printed?', 'for i in range(3):
    print(i, end='' '')', '["0 1 2","1 2 3","0 1 2 3","1 2"]', 0, 'range(3) produces 0, 1, and 2.', '["loops","range"]'),
('python', 2, 'Which statement immediately exits a loop?', '', '["skip","continue","break","return-loop"]', 2, 'break terminates the nearest loop.', '["loops","control-flow"]'),
('python', 2, 'What does continue do inside a loop?', '', '["Ends the program","Skips to the next iteration","Restarts Python","Exits all loops"]', 1, 'continue skips the rest of the current iteration.', '["loops"]'),
('python', 2, 'Which condition checks whether x is equal to 10?', '', '["x = 10","x == 10","x := 10","x === 10"]', 1, '== is Python''s equality comparison operator.', '["operators","conditions"]'),
('python', 2, 'What is list(range(2, 7, 2))?', '', '["[2, 4, 6]","[2, 4, 6, 8]","[2, 3, 4, 5, 6]","[7, 5, 3]"]', 0, 'range(2,7,2) starts at 2, stops before 7, and steps by 2.', '["range"]'),
('python', 2, 'Which operator means logical AND in Python?', '', '["&&","&","and","AND()"]', 2, 'The Boolean operator is the keyword and.', '["boolean","operators"]'),
('python', 2, 'What is the result of 5 != 4?', '', '["True","False","5","Error"]', 0, '!= tests inequality; 5 and 4 are different.', '["operators"]'),
('python', 2, 'Which loop is usually best when the number of iterations is known?', '', '["for","while only","do-while","repeat-until"]', 0, 'A for loop is typically used to iterate over a known sequence or range.', '["loops"]'),
('python', 2, 'What is printed?', 'x = 8
if x < 5:
    print(''A'')
else:
    print(''B'')', '["A","B","C","Nothing"]', 1, '8 is not less than 5, so the else branch prints B.', '["conditions"]'),
('python', 2, 'What does range(5) stop before?', '', '["4","5","6","It never stops"]', 1, 'The stop value is exclusive, so range(5) stops before 5.', '["range"]'),
('python', 3, 'Which data structure stores key-value pairs?', '', '["list","tuple","dict","set"]', 2, 'A dict maps keys to values.', '["dict"]'),
('python', 3, 'Which collection automatically removes duplicate values?', '', '["list","tuple","set","string"]', 2, 'A set contains unique elements.', '["set"]'),
('python', 3, 'What is [x*x for x in range(3)]?', '', '["[0,1,4]","[1,4,9]","[0,1,2]","[0,2,4]"]', 0, 'The comprehension squares 0, 1, and 2.', '["comprehensions"]'),
('python', 3, 'What does a Python function return if no return statement is executed?', '', '["0","False","None","Empty string"]', 2, 'Functions return None implicitly.', '["functions"]'),
('python', 3, 'Which syntax creates a one-element tuple?', '', '["(5)","[5]","(5,)","{5}"]', 2, 'The trailing comma makes (5,) a tuple.', '["tuple"]');

INSERT INTO `questions` (`language`,`level`,`text`,`code`,`options`,`correct_index`,`explanation`,`tags`) VALUES
('python', 3, 'What is {''a'':1}.get(''b'', 0)?', '', '["1","0","None","KeyError"]', 1, 'dict.get returns the provided default when the key is missing.', '["dict"]'),
('python', 3, 'Which statement adds 4 to the end of list a?', '', '["a.add(4)","a.push(4)","a.append(4)","append(a,4)"]', 2, 'list.append adds one item to the end.', '["list"]'),
('python', 3, 'What is the main difference between a list and a tuple?', '', '["Tuples are immutable","Lists cannot store strings","Tuples are always sorted","Lists are key-value maps"]', 0, 'Tuples are immutable while lists are mutable.', '["list","tuple"]'),
('python', 3, 'What does *args collect in a function parameter list?', '', '["Keyword arguments into a dict","Extra positional arguments into a tuple","Only integers","Return values"]', 1, '*args gathers extra positional arguments into a tuple.', '["functions"]'),
('python', 3, 'What does **kwargs collect?', '', '["Extra keyword arguments into a dict","Positional arguments into a list","Exceptions","Modules"]', 0, '**kwargs gathers keyword arguments into a dictionary.', '["functions","dict"]'),
('python', 4, 'What is the purpose of try/except?', '', '["Loop control","Exception handling","Import optimization","Type casting"]', 1, 'try/except catches and handles exceptions.', '["exceptions"]'),
('python', 4, 'Which method is called when an object is created from a class?', '', '["__start__","__init__","__newobj__","constructor()"]', 1, '__init__ initializes a newly created instance.', '["oop"]'),
('python', 4, 'What does inheritance allow?', '', '["A class to reuse/extend another class","A variable to change type","A loop to restart","A module to import itself"]', 0, 'Inheritance lets subclasses reuse and extend base-class behavior.', '["oop","inheritance"]'),
('python', 4, 'Which built-in function creates an iterator from an iterable?', '', '["iterate()","next()","iter()","yield()"]', 2, 'iter() returns an iterator object.', '["iterators"]'),
('python', 4, 'What does next(it) do?', '', '["Creates a list","Gets the next item from an iterator","Resets an iterator","Sorts items"]', 1, 'next() requests the next value from an iterator.', '["iterators"]'),
('python', 4, 'What is a decorator commonly used for?', '', '["Changing function/class behavior without editing its core body","Declaring integers","Starting threads only","Deleting modules"]', 0, 'Decorators wrap or modify functions/classes declaratively.', '["decorators"]'),
('python', 4, 'Which block executes whether or not an exception occurs?', '', '["catch","else only","finally","raise"]', 2, 'finally executes after try/except regardless of whether an exception was raised.', '["exceptions"]'),
('python', 4, 'What does raise do?', '', '["Imports a module","Explicitly triggers an exception","Increases a number","Creates a generator"]', 1, 'raise is used to signal an exception.', '["exceptions"]'),
('python', 4, 'Which special method defines a user-friendly string representation for str(obj)?', '', '["__repr_only__","__str__","__print__","__text__"]', 1, '__str__ is used by str() and print() for readable representation.', '["oop","dunder"]'),
('python', 4, 'What does @staticmethod mean?', '', '["Method receives self automatically","Method receives cls automatically","Method receives neither self nor cls automatically","Method cannot return"]', 2, 'A static method does not receive an implicit instance or class argument.', '["oop"]'),
('python', 5, 'What does yield do in a Python function?', '', '["Terminates Python","Makes the function a generator that can resume","Imports asyncio","Locks the GIL"]', 1, 'yield produces a value and suspends function state, creating generator behavior.', '["generators"]'),
('python', 5, 'Which keyword is used to wait for an awaitable inside async code?', '', '["wait","yield","await","pause"]', 2, 'await suspends the coroutine until the awaitable completes.', '["async"]'),
('python', 5, 'What is the GIL in CPython primarily associated with?', '', '["Only one thread executes Python bytecode at a time in a process","Preventing all concurrency","Encrypting memory","Garbage collection only"]', 0, 'The Global Interpreter Lock allows one thread at a time to execute Python bytecode in a CPython process.', '["gil","concurrency"]'),
('python', 5, 'Which module is the standard foundation for async/await event-loop programming?', '', '["thread","asyncio","parallel","awaitlib"]', 1, 'asyncio provides event loops, tasks, and async I/O primitives.', '["async"]'),
('python', 5, 'What is a metaclass?', '', '["A class whose instances are classes","A faster list","A thread pool","A database schema"]', 0, 'Metaclasses define how classes themselves are created and behave.', '["metaclasses"]'),
('python', 5, 'Which special method is central to the context manager protocol for entering a with block?', '', '["__open__","__enter__","__with__","__begin__"]', 1, '__enter__ is called when entering a with statement.', '["context-manager"]'),
('python', 5, 'Which tool is most appropriate for CPU-bound parallelism that bypasses the CPython GIL by using separate processes?', '', '["multiprocessing","asyncio.sleep","itertools","logging"]', 0, 'multiprocessing uses separate processes and can run Python bytecode on multiple CPU cores.', '["concurrency","performance"]'),
('python', 5, 'What is memoization?', '', '["Deleting cached values","Caching function results for repeated inputs","Converting code to bytecode manually","A threading lock"]', 1, 'Memoization stores previous results to avoid recomputation.', '["performance"]'),
('python', 5, 'What is the purpose of __slots__ in a class?', '', '["It can restrict instance attributes and reduce per-instance memory","It makes every method async","It disables inheritance","It enables SQL"]', 0, '__slots__ can avoid a per-instance __dict__ and constrain attributes.', '["performance","oop"]'),
('python', 5, 'Which statement about generators is true?', '', '["They materialize every value immediately","They produce values lazily","They cannot be iterated","They require threads"]', 1, 'Generators yield values on demand, making them lazy.', '["generators","performance"]');

INSERT INTO `questions` (`language`,`level`,`text`,`code`,`options`,`correct_index`,`explanation`,`tags`) VALUES
('cpp', 1, 'Which header is commonly used for std::cout?', '', '["<stdio.h>","<iostream>","<string.h>","<math>"]', 1, 'std::cout is declared in <iostream>.', '["headers","io"]'),
('cpp', 1, 'Which statement prints text using the standard C++ stream?', '', '["printf only","std::cout << \\"Hi\\";","System.out.println(\\"Hi\\");","print(\\"Hi\\")"]', 1, 'std::cout with << writes to standard output.', '["io"]'),
('cpp', 1, 'Which type typically stores whole numbers?', '', '["int","float only","char* only","bool[]"]', 0, 'int is a standard integer type.', '["types"]'),
('cpp', 1, 'Which symbol ends most C++ statements?', '', '[":",";",".",","]', 1, 'Most C++ statements end with a semicolon.', '["syntax"]'),
('cpp', 1, 'What is the standard entry function of a C++ program?', '', '["start()","main()","run()","init()"]', 1, 'Program execution begins in main().', '["syntax"]'),
('cpp', 1, 'Which operator gets the address of a variable?', '', '["*","&","->","::"]', 1, 'Unary & returns an object''s address.', '["operators"]'),
('cpp', 1, 'Which keyword creates a compile-time constant variable?', '', '["const","fixed","final","static-only"]', 0, 'const prevents modification through that name.', '["types"]'),
('cpp', 1, 'Which namespace contains cout, cin, string, and vector?', '', '["system","cpp","std","global"]', 2, 'The C++ standard library uses namespace std.', '["namespace"]'),
('cpp', 1, 'Which operator performs remainder on integers?', '', '["/","%","//","mod()"]', 1, '% computes the remainder.', '["operators"]'),
('cpp', 1, 'What does std::cin >> x do?', '', '["Prints x","Reads input into x","Deletes x","Casts x"]', 1, 'The extraction operator reads formatted input from std::cin.', '["io"]'),
('cpp', 2, 'Which loop is ideal for iterating a known number of times?', '', '["for","switch","try","namespace"]', 0, 'for loops are commonly used for counted iteration.', '["loops"]'),
('cpp', 2, 'What is passed when a parameter is declared int& x?', '', '["A copy","A reference to the original int","A pointer value only","A string"]', 1, 'int& is an lvalue reference, allowing access to the original object.', '["references"]'),
('cpp', 2, 'Which container represents a fixed-size built-in array?', '', '["int a[5]","vector<int> only","map<int,int>","set<int>"]', 0, 'int a[5] declares a built-in array of five ints.', '["arrays"]'),
('cpp', 2, 'What does break do in a loop?', '', '["Skips one iteration","Exits the nearest loop","Returns from every function","Restarts loop"]', 1, 'break terminates the nearest loop/switch.', '["loops"]'),
('cpp', 2, 'Which keyword skips to the next loop iteration?', '', '["next","continue","skip","pass"]', 1, 'continue starts the next iteration.', '["loops"]'),
('cpp', 2, 'Which syntax declares a function returning int?', '', '["int f()","f(): int","function int f","def f()->int"]', 0, 'C++ puts the return type before the function name.', '["functions"]'),
('cpp', 2, 'What is the first valid index of an array?', '', '["1","0","-1","Depends on compiler"]', 1, 'C++ arrays are zero-indexed.', '["arrays"]'),
('cpp', 2, 'Which operator is logical AND?', '', '["and only invalid","&&","& only","||"]', 1, '&& is the standard logical AND operator (and is an alternative token, but && is canonical).', '["operators"]'),
('cpp', 2, 'What does sizeof(int) return?', '', '["Value of an int","Size in bytes of int","Number of digits","Pointer address"]', 1, 'sizeof yields the size of a type/object in bytes.', '["types"]'),
('cpp', 2, 'Which statement creates a reference r to x?', '', '["int r = &x;","int& r = x;","int* r = x;","ref int r = x;"]', 1, 'int& r = x binds r as a reference to x.', '["references"]'),
('cpp', 3, 'Which operator dereferences a pointer p?', '', '["&p","*p","p&","->p"]', 1, 'Unary * accesses the object pointed to.', '["pointers"]'),
('cpp', 3, 'Which keyword dynamically allocates an object?', '', '["alloc","new","malloc-only","create"]', 1, 'new allocates and constructs objects dynamically.', '["memory"]'),
('cpp', 3, 'Which keyword releases memory allocated with new for a single object?', '', '["free","delete","remove","clear"]', 1, 'delete releases a single object allocated with new.', '["memory"]'),
('cpp', 3, 'Which STL container provides dynamic contiguous storage?', '', '["std::vector","std::map","std::set","std::queue only"]', 0, 'std::vector is a resizable contiguous array.', '["stl","vector"]'),
('cpp', 3, 'What does a class primarily define?', '', '["Only variables","A user-defined type with data and behavior","A preprocessor macro","A namespace alias"]', 1, 'A class groups state and member functions into a type.', '["classes"]');

INSERT INTO `questions` (`language`,`level`,`text`,`code`,`options`,`correct_index`,`explanation`,`tags`) VALUES
('cpp', 3, 'Which access specifier hides members from outside users by default in class?', '', '["public","private","global","protected-only"]', 1, 'Members of class are private by default.', '["classes"]'),
('cpp', 3, 'What is nullptr?', '', '["Integer 0 only","A null pointer literal","A deleted pointer","An empty vector"]', 1, 'nullptr is the type-safe null pointer literal introduced in C++11.', '["pointers"]'),
('cpp', 3, 'Which member access operator is used through a pointer to an object?', '', '[".","->","::","*."]', 1, 'p->member accesses a member via an object pointer.', '["pointers","classes"]'),
('cpp', 3, 'What does std::vector<int> v(3) create?', '', '["Empty vector capacity 3","Vector of 3 ints value-initialized","Array pointer","Map with 3 keys"]', 1, 'The size constructor creates three int elements, value-initialized to 0.', '["vector"]'),
('cpp', 3, 'Why is delete[] used?', '', '["To delete a vector","To release an array allocated with new[]","To clear stack memory","To remove a header"]', 1, 'Memory allocated with new[] must be paired with delete[].', '["memory"]'),
('cpp', 4, 'What is RAII?', '', '["Resource lifetime tied to object lifetime","Runtime array indexing interface","Random access iterator","Reference alias integration"]', 0, 'RAII acquires resources in object construction and releases them in destruction.', '["raii"]'),
('cpp', 4, 'Which smart pointer expresses exclusive ownership?', '', '["std::shared_ptr","std::unique_ptr","std::weak_ptr","raw_ptr"]', 1, 'unique_ptr provides exclusive ownership.', '["smart-pointers"]'),
('cpp', 4, 'Which container stores unique ordered keys by default?', '', '["std::vector","std::set","std::deque","std::list"]', 1, 'std::set stores unique keys ordered by its comparator.', '["stl"]'),
('cpp', 4, 'Which container maps keys to values and orders by key?', '', '["std::map","std::vector","std::stack","std::array"]', 0, 'std::map is an ordered associative key-value container.', '["stl"]'),
('cpp', 4, 'What is a virtual function used for?', '', '["Compile-time macros","Runtime polymorphic dispatch","Memory allocation only","Namespaces"]', 1, 'virtual enables dynamic dispatch through base references/pointers.', '["oop","polymorphism"]'),
('cpp', 4, 'Why should a polymorphic base class usually have a virtual destructor?', '', '["To make constructors virtual","To ensure derived destructors run when deleting via base pointer","To speed copying","To disable inheritance"]', 1, 'A virtual destructor allows correct derived destruction through a base pointer.', '["oop"]'),
('cpp', 4, 'What does std::move primarily do?', '', '["Physically move bytes immediately","Cast to an rvalue/xvalue to enable move operations","Delete the source","Copy data"]', 1, 'std::move is a cast that permits move overloads to be selected.', '["move-semantics"]'),
('cpp', 4, 'What is std::weak_ptr useful for?', '', '["Exclusive ownership","Non-owning observation of shared_ptr-managed objects","Raw allocation","Array sorting"]', 1, 'weak_ptr observes shared ownership without increasing the strong reference count.', '["smart-pointers"]'),
('cpp', 4, 'Which algorithm sorts a random-access range?', '', '["std::order","std::sort","std::arrange","std::rank"]', 1, 'std::sort sorts a range given random-access iterators.', '["algorithms","stl"]'),
('cpp', 4, 'What does a pure virtual function typically contain in its declaration?', '', '["= 0","= null","virtual only with no semicolon","abstract"]', 0, 'A pure virtual function is declared with = 0.', '["oop"]'),
('cpp', 5, 'What is the Rule of Five concerned with?', '', '["Five loop types","Copy/move construction, copy/move assignment, and destruction","Five STL containers","Five template parameters"]', 1, 'Resource-owning classes may need all five special member functions.', '["rule-of-five"]'),
('cpp', 5, 'What is perfect forwarding commonly implemented with?', '', '["std::forward and forwarding references","std::sort","std::weak_ptr","goto"]', 0, 'std::forward preserves value category in forwarding contexts.', '["templates","move-semantics"]'),
('cpp', 5, 'What does template<typename T> introduce?', '', '["A runtime variable","A type template parameter","A namespace","A thread"]', 1, 'It declares T as a template type parameter.', '["templates"]'),
('cpp', 5, 'Which standard type represents a thread of execution?', '', '["std::thread","std::process","std::fiber always","std::async_thread"]', 0, 'std::thread represents a thread.', '["concurrency"]'),
('cpp', 5, 'What is a data race?', '', '["Two threads access the same memory concurrently with at least one unsynchronized write","Any two threads running","A slow mutex","A race in sorting"]', 0, 'Unsynchronized conflicting accesses cause a data race and undefined behavior.', '["concurrency"]'),
('cpp', 5, 'Which primitive provides mutual exclusion?', '', '["std::mutex","std::vector","std::future only","std::tuple"]', 0, 'std::mutex protects critical sections through locking.', '["concurrency"]'),
('cpp', 5, 'What does std::lock_guard do?', '', '["Manually allocates a mutex","Uses RAII to lock/unlock a mutex","Creates a thread pool","Deletes locks"]', 1, 'lock_guard locks on construction and unlocks on destruction.', '["concurrency","raii"]'),
('cpp', 5, 'What is an rvalue reference declared with?', '', '["T&","T&&","T*","const T only"]', 1, 'T&& denotes an rvalue reference in ordinary contexts.', '["move-semantics"]'),
('cpp', 5, 'Which feature can compute values/types during compilation?', '', '["Templates and constexpr","Only virtual functions","Only threads","iostream"]', 0, 'Templates and constexpr enable extensive compile-time computation.', '["templates","constexpr"]'),
('cpp', 5, 'What is undefined behavior?', '', '["Behavior fully specified by the standard","Behavior for which the C++ standard imposes no requirements","A compiler warning only","A caught exception"]', 1, 'For undefined behavior, the standard imposes no requirements on program behavior.', '["language-rules"]');

INSERT INTO `questions` (`language`,`level`,`text`,`code`,`options`,`correct_index`,`explanation`,`tags`) VALUES
('html', 1, 'Which element is the root element of an HTML document?', '', '["<body>","<html>","<head>","<main>"]', 1, '<html> is the document''s root element.', '["structure"]'),
('html', 1, 'Which tag creates the largest default heading?', '', '["<h6>","<heading>","<h1>","<title>"]', 2, '<h1> is the highest-level heading.', '["tags"]'),
('html', 1, 'Which tag creates a paragraph?', '', '["<p>","<para>","<text>","<section>"]', 0, '<p> represents a paragraph.', '["tags"]'),
('html', 1, 'Where is the page title shown in browser tabs usually defined?', '', '["<meta>","<title>","<h1>","<caption>"]', 1, 'The <title> element in <head> sets the document title.', '["structure"]'),
('html', 1, 'Which attribute commonly provides alternative text for an image?', '', '["title","alt","src","href"]', 1, 'alt provides a text alternative.', '["attributes","images"]'),
('html', 1, 'Which element inserts a line break?', '', '["<lb>","<break>","<br>","<newline>"]', 2, '<br> represents a line break.', '["tags"]'),
('html', 1, 'Which declaration identifies HTML5?', '', '["<html5>","<!DOCTYPE html>","<doctype=5>","<meta html5>"]', 1, '<!DOCTYPE html> is the HTML5 doctype.', '["structure"]'),
('html', 1, 'Which tag contains the visible page content?', '', '["<head>","<body>","<meta>","<link>"]', 1, 'Visible document content belongs in <body>.', '["structure"]'),
('html', 1, 'Which attribute specifies an image URL?', '', '["href","src","path","link"]', 1, 'The img src attribute identifies the image resource.', '["images"]'),
('html', 1, 'Which syntax is an HTML comment?', '', '["// comment","<!-- comment -->","# comment","/* comment */"]', 1, 'HTML comments use <!-- ... -->.', '["syntax"]'),
('html', 2, 'Which element creates a hyperlink?', '', '["<link>","<a>","<href>","<url>"]', 1, '<a> is the anchor element.', '["links"]'),
('html', 2, 'Which attribute specifies a hyperlink destination?', '', '["src","href","action","target-only"]', 1, 'href contains the link destination.', '["links"]'),
('html', 2, 'Which element creates an unordered list?', '', '["<ol>","<ul>","<li>","<list>"]', 1, '<ul> represents an unordered list.', '["lists"]'),
('html', 2, 'Which element represents a table row?', '', '["<td>","<tr>","<th>","<row>"]', 1, '<tr> represents a table row.', '["tables"]'),
('html', 2, 'Which element creates a form?', '', '["<input>","<form>","<fieldset>","<label>"]', 1, '<form> groups controls for submission.', '["forms"]'),
('html', 2, 'Which input type hides typed characters for password entry?', '', '["text","hidden","password","secret"]', 2, 'type=password masks the entered value visually.', '["forms"]'),
('html', 2, 'Which attribute makes a form control mandatory in native validation?', '', '["must","required","validate","needed"]', 1, 'required causes native constraint validation to reject empty submission.', '["forms","validation"]'),
('html', 2, 'Which tag defines a table header cell?', '', '["<th>","<thead-only>","<tdh>","<headcell>"]', 0, '<th> is a header cell.', '["tables"]'),
('html', 2, 'Which attribute on <a> can open a link in a new browsing context?', '', '["target=\\"_blank\\"","new=\\"true\\"","window=\\"new\\"","open=\\"tab\\""]', 0, 'target=_blank requests a new browsing context, often a tab.', '["links"]'),
('html', 2, 'Which element groups options in a drop-down list?', '', '["<select>","<choice>","<menuitem>","<dropdown>"]', 0, '<select> contains <option> elements.', '["forms"]'),
('html', 3, 'Which semantic element is intended for the main unique content of a page?', '', '["<main>","<div>","<span>","<b>"]', 0, '<main> identifies the dominant content of the document body.', '["semantic"]'),
('html', 3, 'Which element is appropriate for site navigation links?', '', '["<nav>","<links>","<menuonly>","<aside>"]', 0, '<nav> marks a major navigation section.', '["semantic"]'),
('html', 3, 'Which element represents a self-contained composition such as a post?', '', '["<article>","<content>","<divpost>","<entry>"]', 0, '<article> is intended for independently distributable/self-contained content.', '["semantic"]'),
('html', 3, 'Which element associates visible text with a form control?', '', '["<label>","<legend> only","<caption>","<text>"]', 0, '<label> provides an accessible label for a form control.', '["forms","accessibility"]'),
('html', 3, 'Which input attribute constrains a text value with a regular expression?', '', '["regex","pattern","match","constraint"]', 1, 'pattern supplies a regular expression for native validation.', '["validation"]');

INSERT INTO `questions` (`language`,`level`,`text`,`code`,`options`,`correct_index`,`explanation`,`tags`) VALUES
('html', 3, 'Which input type provides native email-format validation?', '', '["mail","email","text-email","address"]', 1, 'type=email enables email-oriented semantics and validation.', '["forms","validation"]'),
('html', 3, 'Which semantic element is suited to tangential/sidebar content?', '', '["<aside>","<main>","<footer-only>","<sidebar>"]', 0, '<aside> represents content indirectly related to surrounding content.', '["semantic"]'),
('html', 3, 'Which element can provide a caption for a <figure>?', '', '["<caption>","<figcaption>","<legend>","<title>"]', 1, '<figcaption> captions a <figure>.', '["semantic"]'),
('html', 3, 'What does the minlength attribute do?', '', '["Sets minimum CSS width","Requires a minimum number of characters","Sets minimum numeric value for all controls","Limits forms"]', 1, 'minlength defines the minimum text length for applicable controls.', '["validation"]'),
('html', 3, 'Which element groups related form controls with an optional legend?', '', '["<fieldset>","<group>","<section-form>","<formset>"]', 0, '<fieldset> groups related controls and can use <legend>.', '["forms"]'),
('html', 4, 'What is the best first choice for labeling a form input?', '', '["aria-label always","A visible <label> associated with the control","placeholder only","title only"]', 1, 'A properly associated visible label is generally the most robust accessible name.', '["accessibility"]'),
('html', 4, 'What does aria-hidden="true" do?', '', '["Deletes an element","Hides it from the accessibility tree","Makes it display:none","Prevents network loading"]', 1, 'aria-hidden removes the element/subtree from accessibility APIs but does not visually hide it.', '["aria"]'),
('html', 4, 'Which attribute associates a <label> with an input by ID?', '', '["name","for","target","control"]', 1, 'label''s for value matches the control''s id.', '["accessibility","forms"]'),
('html', 4, 'Why should placeholder text not be the only label?', '', '["It always breaks CSS","It disappears during entry and is not a reliable accessible label","It cannot contain letters","Browsers forbid it"]', 1, 'Placeholders are hints, not robust persistent labels.', '["accessibility"]'),
('html', 4, 'Which landmark element identifies page navigation?', '', '["<nav>","<span role=''text''>","<b>","<i>"]', 0, '<nav> carries navigation semantics.', '["accessibility","semantic"]'),
('html', 4, 'When should role="button" be preferred over <button>?', '', '["Always","Only when a native button genuinely cannot be used and full keyboard behavior is implemented","For every link","Never under any circumstance"]', 1, 'Native <button> is preferred; custom roles require recreating native interactions.', '["aria","accessibility"]'),
('html', 4, 'What should meaningful images generally have?', '', '["An informative alt value","alt omitted always","Only a filename","A CSS title"]', 0, 'Meaningful images need text alternatives describing their purpose/content.', '["accessibility","images"]'),
('html', 4, 'What should a purely decorative image typically use?', '', '["alt=\\"\\"","alt=\\"decorative image\\"","No src","role=\\"heading\\""]', 0, 'An empty alt usually lets assistive tech ignore decorative images.', '["accessibility","images"]'),
('html', 4, 'Why use heading levels logically?', '', '["Only to change font size","To communicate document structure to users and assistive technology","To load faster","To enable forms"]', 1, 'Headings convey hierarchical document structure.', '["accessibility","semantic"]'),
('html', 4, 'Which native element supports keyboard activation and button semantics automatically?', '', '["<div>","<span>","<button>","<section>"]', 2, '<button> provides native semantics and keyboard interaction.', '["accessibility"]'),
('html', 5, 'What does rel="preload" generally do?', '', '["Hints that a current-page resource should be fetched with high priority","Creates a hyperlink","Defers every script","Blocks caching"]', 0, 'preload declares a resource likely needed soon by the current page.', '["performance","resource-hints"]'),
('html', 5, 'What does rel="preconnect" hint to the browser?', '', '["Parse HTML twice","Establish an early connection to an origin","Cache all images forever","Open a new tab"]', 1, 'preconnect can perform DNS/TCP/TLS setup early for an origin.', '["performance","resource-hints"]'),
('html', 5, 'Which meta tag commonly provides a search-result summary?', '', '["meta name=\\"description\\"","meta name=\\"keywords\\" only","meta name=\\"title\\"","meta http-equiv=\\"seo\\""]', 0, 'meta description commonly supplies descriptive snippet text to search engines.', '["seo"]'),
('html', 5, 'What is the purpose of the canonical link relation?', '', '["Declare a preferred URL for substantially duplicate pages","Load CSS","Start a service worker","Set language"]', 0, 'rel=canonical signals the preferred representative URL.', '["seo"]'),
('html', 5, 'Which attribute can defer offscreen image loading in supporting browsers?', '', '["loading=\\"lazy\\"","defer=\\"image\\"","async=\\"img\\"","fetch=\\"later\\""]', 0, 'loading=lazy requests lazy loading for eligible images/iframes.', '["performance"]'),
('html', 5, 'What is a custom element name required to contain?', '', '["An underscore","A hyphen","A colon","A number"]', 1, 'Custom element names must contain a hyphen, such as user-card.', '["web-components"]'),
('html', 5, 'Which Web Components feature provides DOM/style encapsulation?', '', '["Shadow DOM","LocalStorage","Canvas","WebSocket"]', 0, 'Shadow DOM provides an encapsulated DOM subtree and style boundary.', '["web-components"]'),
('html', 5, 'What does the <template> element provide?', '', '["Inert markup that can be cloned/instantiated later","An automatic server template engine","A CSS reset","A navigation menu"]', 0, '<template> stores markup that is not rendered until instantiated.', '["web-components"]'),
('html', 5, 'Which script attribute downloads in parallel and executes after HTML parsing, preserving order among defer scripts?', '', '["async","defer","blocking","lazy"]', 1, 'defer scripts execute after parsing and preserve document order.', '["performance","scripts"]'),
('html', 5, 'Which attribute helps communicate the document language to assistive tech and search engines?', '', '["lang on <html>","charset only","dir only","name"]', 0, 'The lang attribute on the root element identifies document language.', '["seo","accessibility"]');

INSERT INTO `questions` (`language`,`level`,`text`,`code`,`options`,`correct_index`,`explanation`,`tags`) VALUES
('java', 1, 'Which method is the standard entry point of a Java application?', '', '["start()","public static void main(String[] args)","runMain()","init()"]', 1, 'The JVM invokes public static void main(String[] args).', '["syntax"]'),
('java', 1, 'Which primitive type stores true/false values?', '', '["bool","boolean","Boolean only","bit"]', 1, 'boolean is Java''s primitive logical type.', '["types"]'),
('java', 1, 'Which statement prints a line to standard output?', '', '["print()","System.out.println()","cout <<","Console.write()"]', 1, 'System.out.println writes a line to standard output.', '["io"]'),
('java', 1, 'Which keyword declares a class?', '', '["class","type","struct","object"]', 0, 'Java classes are declared with class.', '["classes"]'),
('java', 1, 'Which type commonly stores whole numbers?', '', '["int","String","double only","boolean"]', 0, 'int is a 32-bit signed integer primitive.', '["types"]'),
('java', 1, 'Which operator compares primitive numeric values for equality?', '', '["=","==","===","equals only"]', 1, '== compares primitive values.', '["operators"]'),
('java', 1, 'Which symbol terminates most Java statements?', '', '[":",";",",","."]', 1, 'Most Java statements end with a semicolon.', '["syntax"]'),
('java', 1, 'Which keyword creates a new object?', '', '["make","new","create","alloc"]', 1, 'new allocates and constructs an object.', '["objects"]'),
('java', 1, 'Which type stores a single UTF-16 code unit?', '', '["char","string","byte only","rune"]', 0, 'char is a 16-bit UTF-16 code unit.', '["types"]'),
('java', 1, 'Which access modifier makes a member accessible everywhere (subject to module rules)?', '', '["private","protected","public","local"]', 2, 'public provides the broadest normal access.', '["access"]'),
('java', 2, 'Which loop is commonly used for counted iteration?', '', '["for","switch","try","class"]', 0, 'for is commonly used when iteration count is controlled by an index.', '["loops"]'),
('java', 2, 'What is the first index of a Java array?', '', '["1","0","-1","Compiler-dependent"]', 1, 'Java arrays are zero-indexed.', '["arrays"]'),
('java', 2, 'Which method returns the length of a String?', '', '["length","length()","size()","count()"]', 1, 'String exposes length() as a method.', '["strings"]'),
('java', 2, 'Which field gives an array''s length?', '', '["length","length()","size","count()"]', 0, 'Arrays use the length field, not a method.', '["arrays"]'),
('java', 2, 'Which collection is a resizable list?', '', '["ArrayList","String","HashMap only","Thread"]', 0, 'ArrayList implements a resizable list.', '["collections"]'),
('java', 2, 'Which keyword exits a loop immediately?', '', '["stop","break","exit","continue"]', 1, 'break exits the nearest loop/switch.', '["loops"]'),
('java', 2, 'What does continue do?', '', '["Ends method","Skips to next loop iteration","Creates a thread","Throws exception"]', 1, 'continue moves to the next iteration.', '["loops"]'),
('java', 2, 'Which String comparison checks content equality?', '', '["== always","equals()","same()","compare only"]', 1, 'equals() compares String content; == compares references.', '["strings"]'),
('java', 2, 'Which statement creates an int array of length 5?', '', '["int[] a = new int[5];","int a = [5];","array<int> a(5);","int[5] a;"]', 0, 'new int[5] allocates a five-element int array.', '["arrays"]'),
('java', 2, 'Which enhanced loop syntax iterates elements?', '', '["for (int x : arr)","for x in arr","foreach x arr","loop(arr)"]', 0, 'Java''s enhanced for loop uses colon syntax.', '["loops","arrays"]'),
('java', 3, 'Which keyword establishes class inheritance?', '', '["inherits","extends","implements","superclass"]', 1, 'A class extends another class.', '["inheritance"]'),
('java', 3, 'Which keyword says a class implements an interface?', '', '["extends only","implements","interface-of","uses"]', 1, 'implements lists implemented interfaces.', '["interfaces"]'),
('java', 3, 'Which keyword refers to the current object?', '', '["self","this","current","me"]', 1, 'this references the current instance.', '["oop"]'),
('java', 3, 'Which keyword refers to the parent class context?', '', '["parent","base","super","up"]', 2, 'super accesses superclass constructors/members.', '["inheritance"]'),
('java', 3, 'Which block handles an exception?', '', '["catch","handle","rescue","except"]', 0, 'catch handles a matching thrown exception.', '["exceptions"]');

INSERT INTO `questions` (`language`,`level`,`text`,`code`,`options`,`correct_index`,`explanation`,`tags`) VALUES
('java', 3, 'Which keyword explicitly throws an exception object?', '', '["throws","throw","raise","error"]', 1, 'throw actually throws an exception; throws declares possible propagation.', '["exceptions"]'),
('java', 3, 'Can a Java class extend multiple classes directly?', '', '["Yes, unlimited","No, classes have single inheritance","Only two","Only abstract classes"]', 1, 'Java classes support single class inheritance, though they can implement multiple interfaces.', '["inheritance"]'),
('java', 3, 'What is method overriding?', '', '["Defining a subclass method with the same signature to replace inherited behavior","Two methods with different parameter lists in same class","Changing variable type","Catching an exception"]', 0, 'Overriding supplies a subtype-specific implementation of an inherited instance method.', '["polymorphism"]'),
('java', 3, 'What is method overloading?', '', '["Same method name with different parameter lists","Same signature in subclass only","Using many threads","Multiple return statements"]', 0, 'Overloading uses the same name with distinct parameter lists.', '["functions"]'),
('java', 3, 'Which modifier prevents a class from being subclassed?', '', '["static","final","const","sealed-only always"]', 1, 'A final class cannot be extended.', '["classes"]'),
('java', 4, 'Which collection stores unique elements with hash-based lookup?', '', '["HashSet","ArrayList","LinkedList","TreeMap"]', 0, 'HashSet implements a hash-based set.', '["collections"]'),
('java', 4, 'Why should equals() and hashCode() usually be overridden together?', '', '["Hash-based collections rely on their consistency","The compiler requires it syntactically","To enable loops","To start threads"]', 0, 'Equal objects must produce equal hash codes for hash-based collections to work correctly.', '["equals","hashcode"]'),
('java', 4, 'Which generic declaration means a list of String?', '', '["List<String>","List(string)","List[str]","String<List>"]', 0, 'Java generics use angle brackets.', '["generics"]'),
('java', 4, 'What does Stream.map commonly do?', '', '["Transforms each stream element","Sorts only","Closes the JVM","Mutates every source collection"]', 0, 'map applies a function to produce transformed stream elements.', '["streams"]'),
('java', 4, 'What does Stream.filter do?', '', '["Keeps elements matching a predicate","Maps keys to values","Starts a thread","Catches errors"]', 0, 'filter retains elements for which the predicate is true.', '["streams"]'),
('java', 4, 'Which interface imposes a natural ordering contract?', '', '["Comparable","Comparator only","Serializable","Cloneable"]', 0, 'Comparable defines compareTo for natural ordering.', '["collections"]'),
('java', 4, 'Which interface supplies an external/custom ordering strategy?', '', '["Comparator","Comparable only","Iterable","Runnable"]', 0, 'Comparator compares two objects independently of their classes'' natural order.', '["collections"]'),
('java', 4, 'What is type erasure in Java generics?', '', '["Most generic type parameters are removed/translated at runtime representation","Objects are deleted","Types become strings","Generics run only at compile-time with no bytecode"]', 0, 'Java implements most generics through erasure, with casts/bridges inserted as needed.', '["generics"]'),
('java', 4, 'Which collection preserves key-value associations?', '', '["Map","Set","Queue","List only"]', 0, 'Map associates keys with values.', '["collections"]'),
('java', 4, 'What does Optional primarily model?', '', '["A value that may or may not be present","A background thread","A mutable integer","A database transaction"]', 0, 'Optional is a container expressing possible absence.', '["optional"]'),
('java', 5, 'Which keyword gives visibility guarantees for reads/writes of a variable across threads but does not make compound actions atomic?', '', '["volatile","final","native","transient"]', 0, 'volatile establishes visibility/order guarantees, but operations like i++ are still not atomic.', '["concurrency","memory-model"]'),
('java', 5, 'Which construct provides intrinsic mutual exclusion around a monitor?', '', '["synchronized","volatile","transient","strictfp"]', 0, 'synchronized acquires an object''s/class''s monitor.', '["concurrency"]'),
('java', 5, 'What is a happens-before relationship?', '', '["A Java Memory Model ordering/visibility guarantee","A syntax rule for loops","A garbage-collector phase only","A class-loading error"]', 0, 'Happens-before defines when effects of one action are guaranteed visible to another.', '["memory-model"]'),
('java', 5, 'Which interface is commonly submitted to an ExecutorService for a task with a return value?', '', '["Callable","Runnable only","Comparable","Iterable"]', 0, 'Callable<V> can return a value and throw checked exceptions.', '["concurrency"]'),
('java', 5, 'Which class represents a result that may become available later from an executor?', '', '["Future","Optional","ThreadLocal","AtomicInteger only"]', 0, 'Future represents an asynchronous computation result.', '["concurrency"]'),
('java', 5, 'What is deadlock?', '', '["Threads wait cyclically for resources and cannot progress","A thread sleeping briefly","A caught exception","A GC pause"]', 0, 'Deadlock occurs when threads wait on one another indefinitely.', '["concurrency"]'),
('java', 5, 'What does AtomicInteger provide?', '', '["Atomic operations on an int value","An immutable Integer","Only volatile reads","A database key"]', 0, 'AtomicInteger supports lock-free/thread-safe atomic operations such as incrementAndGet.', '["concurrency"]'),
('java', 5, 'What is the JVM JIT compiler used for?', '', '["Compiling hot bytecode to native machine code at runtime","Parsing SQL","Writing source files","Only garbage collection"]', 0, 'The JIT optimizes frequently executed bytecode into native code.', '["jvm","performance"]'),
('java', 5, 'Which memory area typically stores per-thread call frames and local variables?', '', '["Java stack","Heap only","Metaspace only","String pool only"]', 0, 'Each thread has a stack containing frames for active method calls.', '["jvm","memory"]'),
('java', 5, 'What is a safepoint in the JVM?', '', '["A state/location where threads can be coordinated for certain VM operations","A checked exception","A synchronized collection","A source-code comment"]', 0, 'Safepoints allow the JVM to bring threads to known states for operations such as parts of GC/deoptimization.', '["jvm"]');

INSERT INTO `questions` (`language`,`level`,`text`,`code`,`options`,`correct_index`,`explanation`,`tags`) VALUES
('sql', 1, 'Which clause selects columns to return?', '', '["SELECT","WHERE","ORDER","FROM only"]', 0, 'SELECT defines the result expressions/columns.', '["select"]'),
('sql', 1, 'Which clause identifies the source table?', '', '["TABLE","FROM","SOURCE","USING"]', 1, 'FROM names source tables or derived tables.', '["select"]'),
('sql', 1, 'Which clause filters rows before they are returned?', '', '["WHERE","ORDER BY","SELECT","LIMIT only"]', 0, 'WHERE applies row-level predicates.', '["where"]'),
('sql', 1, 'Which clause sorts result rows?', '', '["SORT","ORDER BY","GROUP","RANK"]', 1, 'ORDER BY sorts the result.', '["order"]'),
('sql', 1, 'Which keyword removes duplicate rows from a SELECT result?', '', '["UNIQUE","DISTINCT","ONLY","DEDUP"]', 1, 'SELECT DISTINCT removes duplicate result rows.', '["select"]'),
('sql', 1, 'Which expression counts rows?', '', '["SUM(*)","COUNT(*)","ROWS()","NUMBER(*)"]', 1, 'COUNT(*) counts rows.', '["aggregate"]'),
('sql', 1, 'Which clause commonly limits returned row count in MySQL/PostgreSQL?', '', '["LIMIT","STOP","TOP only everywhere","ROWS"]', 0, 'LIMIT restricts result rows in MySQL/PostgreSQL.', '["limit"]'),
('sql', 1, 'Which operator checks equality?', '', '["=","==","===","EQ"]', 0, 'SQL normally uses = for equality comparisons.', '["operators"]'),
('sql', 1, 'Which keyword represents a missing/unknown value?', '', '["EMPTY","NULL","NONE","UNKNOWNVAL"]', 1, 'NULL represents missing/unknown information.', '["null"]'),
('sql', 1, 'How should NULL usually be tested?', '', '["= NULL","IS NULL","== NULL","EQUALS NULL"]', 1, 'IS NULL tests for nullness.', '["null"]'),
('sql', 2, 'Which join returns matching rows from both sides only?', '', '["INNER JOIN","LEFT JOIN","FULL JOIN","CROSS JOIN"]', 0, 'INNER JOIN returns rows satisfying the join condition on both sides.', '["joins"]'),
('sql', 2, 'Which join keeps all rows from the left table even without a match?', '', '["LEFT JOIN","INNER JOIN","CROSS JOIN","SELF ONLY"]', 0, 'LEFT JOIN preserves unmatched left rows with NULLs on the right.', '["joins"]'),
('sql', 2, 'Which clause groups rows for aggregate calculations?', '', '["GROUP BY","ORDER BY","WHERE","LIMIT"]', 0, 'GROUP BY partitions rows into groups.', '["group-by"]'),
('sql', 2, 'Which function computes an average?', '', '["AVG","MEAN","AVERAGE","MID"]', 0, 'AVG computes the arithmetic mean of non-NULL values.', '["aggregate"]'),
('sql', 2, 'Which function returns the largest value?', '', '["TOP","MAX","GREATESTROW","HIGH"]', 1, 'MAX returns the maximum non-NULL value.', '["aggregate"]'),
('sql', 2, 'Where is a join condition commonly written for explicit JOIN syntax?', '', '["ON","AT","WITH","MATCH"]', 0, 'ON specifies the join predicate.', '["joins"]'),
('sql', 2, 'What does CROSS JOIN produce?', '', '["Cartesian product","Only matching keys","Left rows only","Aggregated rows"]', 0, 'CROSS JOIN pairs every row from one input with every row from the other.', '["joins"]'),
('sql', 2, 'Which clause filters grouped aggregate results?', '', '["HAVING","WHERE only","ORDER BY","ON"]', 0, 'HAVING filters after grouping/aggregation.', '["having"]'),
('sql', 2, 'Which aggregate counts non-NULL values in column x?', '', '["COUNT(x)","COUNT(NULL)","SUM(x) always","ROWS(x)"]', 0, 'COUNT(x) ignores NULL values.', '["aggregate"]'),
('sql', 2, 'Which join can be used to join a table to itself using aliases?', '', '["Self join via ordinary JOIN syntax","Only CROSS APPLY","Impossible","UNION only"]', 0, 'A self join uses the same table multiple times with aliases.', '["joins"]'),
('sql', 3, 'What is a subquery?', '', '["A query nested inside another SQL statement","A database backup","A table index","A transaction log"]', 0, 'A subquery is a nested SELECT used by an outer statement.', '["subquery"]'),
('sql', 3, 'Which expression supports conditional values inside a query?', '', '["CASE","IFBLOCK only","SWITCH","MATCHCASE"]', 0, 'CASE implements conditional expressions in standard SQL.', '["case"]'),
('sql', 3, 'What does UNION do by default?', '', '["Combines compatible result sets and removes duplicates","Joins columns by key","Keeps only duplicates","Sorts one table only"]', 0, 'UNION combines rows and performs duplicate elimination.', '["set-operators"]'),
('sql', 3, 'What does UNION ALL do?', '', '["Combines result sets and keeps duplicates","Only returns common rows","Removes all duplicates","Joins tables horizontally"]', 0, 'UNION ALL concatenates compatible result sets without duplicate elimination.', '["set-operators"]'),
('sql', 3, 'What is the key difference between WHERE and HAVING?', '', '["WHERE filters rows before grouping; HAVING filters groups after aggregation","They are identical","HAVING sorts rows","WHERE can only use text"]', 0, 'WHERE is evaluated before grouping; HAVING is for grouped results.', '["where","having"]');

INSERT INTO `questions` (`language`,`level`,`text`,`code`,`options`,`correct_index`,`explanation`,`tags`) VALUES
('sql', 3, 'Which operator tests whether a value appears in a subquery/list?', '', '["IN","HAS","CONTAINS","AMONG"]', 0, 'IN compares a value with a set/list of values.', '["subquery"]'),
('sql', 3, 'Which predicate tests whether a subquery returns at least one row?', '', '["EXISTS","PRESENT","ANYROW","HASROW"]', 0, 'EXISTS is true when its subquery returns at least one row.', '["subquery"]'),
('sql', 3, 'Which expression replaces NULL with a fallback in standard SQL?', '', '["COALESCE","REPLACE_NULL","DEFAULTIF","NVL only standard"]', 0, 'COALESCE returns the first non-NULL argument.', '["null"]'),
('sql', 3, 'Which set operator returns rows common to both compatible result sets in supporting DBMSs?', '', '["INTERSECT","UNION ALL","EXCEPT","JOIN"]', 0, 'INTERSECT returns rows present in both inputs.', '["set-operators"]'),
('sql', 3, 'A correlated subquery is one that...', '', '["References columns from an outer query","Cannot reference any table","Always returns one row","Must use UNION"]', 0, 'Correlated subqueries depend on values from the outer row/query.', '["subquery"]'),
('sql', 4, 'What is the main purpose of an index?', '', '["Speed up certain data retrieval operations at storage/write cost","Encrypt rows","Replace primary keys","Guarantee no NULLs"]', 0, 'Indexes provide lookup/order structures that can reduce query work, with maintenance/storage tradeoffs.', '["indexes"]'),
('sql', 4, 'What does a transaction provide as a unit?', '', '["A group of operations committed or rolled back together","A permanent index","A view only","A stored string"]', 0, 'Transactions group operations into an atomic unit of work.', '["transactions"]'),
('sql', 4, 'Which command makes current transaction changes permanent?', '', '["COMMIT","SAVE","APPLY","FINISH"]', 0, 'COMMIT completes the transaction successfully.', '["transactions"]'),
('sql', 4, 'Which command abandons uncommitted transaction changes?', '', '["ROLLBACK","UNDO TABLE","DELETE TRANSACTION","RESET"]', 0, 'ROLLBACK reverses changes made in the current transaction (subject to DB semantics).', '["transactions"]'),
('sql', 4, 'What is normalization intended to reduce?', '', '["Redundant data and update anomalies","All joins","Every index","Query permissions"]', 0, 'Normalization organizes relations to reduce redundancy and anomalies.', '["normalization"]'),
('sql', 4, 'What is a primary key?', '', '["A constraint identifying each row uniquely and non-null","Any indexed text column","A foreign table","A query alias"]', 0, 'A primary key uniquely identifies each row and cannot be NULL.', '["constraints"]'),
('sql', 4, 'What is a foreign key used for?', '', '["Enforcing referential relationships between tables","Sorting a table","Encrypting values","Creating views"]', 0, 'Foreign keys enforce referential integrity against candidate/primary keys.', '["constraints"]'),
('sql', 4, 'Which isolation anomaly involves reading uncommitted data from another transaction?', '', '["Dirty read","Phantom only","Lost sort","Hash collision"]', 0, 'A dirty read observes another transaction''s uncommitted changes.', '["transactions","isolation"]'),
('sql', 4, 'Which isolation level is the strongest among the standard four?', '', '["READ UNCOMMITTED","READ COMMITTED","REPEATABLE READ","SERIALIZABLE"]', 3, 'SERIALIZABLE provides behavior equivalent to serial transaction execution under the standard model.', '["isolation"]'),
('sql', 4, 'What is a composite index?', '', '["An index over more than one column","Two databases","A duplicated index file","A primary key only"]', 0, 'A composite/multicolumn index contains multiple indexed columns.', '["indexes"]'),
('sql', 5, 'Which function assigns a sequential number within a window partition/order?', '', '["ROW_NUMBER()","COUNTROW()","INDEX()","SEQ()"]', 0, 'ROW_NUMBER() numbers rows according to the window ordering.', '["window-functions"]'),
('sql', 5, 'Which clause defines partitioning/order for a window function?', '', '["OVER","WINDOWBY only","GROUP WINDOW","ON"]', 0, 'OVER(...) defines the window specification.', '["window-functions"]'),
('sql', 5, 'What is the key difference between GROUP BY and window functions?', '', '["Window functions can compute aggregates/ranks without collapsing rows","They are identical","GROUP BY never aggregates","Window functions cannot order"]', 0, 'Window functions retain individual rows while computing values across a related window.', '["window-functions"]'),
('sql', 5, 'What does EXPLAIN commonly show?', '', '["A database''s planned/actual strategy for executing a query, depending on DBMS/options","Table contents only","User passwords","SQL syntax help only"]', 0, 'EXPLAIN exposes an execution plan or planner estimates.', '["execution-plan"]'),
('sql', 5, 'Why can SELECT * be undesirable in performance-sensitive code?', '', '["It may fetch unnecessary columns and increase I/O/network work","It is invalid SQL","It disables indexes always","It deletes duplicates"]', 0, 'Selecting only needed columns can reduce transferred/read data and improve plan options.', '["performance"]'),
('sql', 5, 'What is a covering index?', '', '["An index containing all data columns needed to satisfy a query without extra table lookups in supported engines","An encrypted index","A backup index","A foreign key"]', 0, 'A covering index can answer required columns directly from the index structure.', '["indexes","performance"]'),
('sql', 5, 'Which window function gives equal values the same rank and leaves gaps after ties?', '', '["RANK()","DENSE_RANK()","ROW_NUMBER()","NTILE()"]', 0, 'RANK gives ties the same rank and skips subsequent rank numbers.', '["window-functions"]'),
('sql', 5, 'Which window function gives equal values the same rank without gaps?', '', '["DENSE_RANK()","RANK()","ROW_NUMBER()","LEAD()"]', 0, 'DENSE_RANK does not leave gaps after ties.', '["window-functions"]'),
('sql', 5, 'What does LAG(value) do in a window?', '', '["Accesses a value from a preceding row in the window ordering","Sorts descending","Groups rows","Returns next row only"]', 0, 'LAG returns a value from an earlier row relative to the current row.', '["window-functions"]'),
('sql', 5, 'A query uses an index but is still slow. What should you inspect next?', '', '["The execution plan, row estimates, selectivity, joins, and I/O","Only rename the table","Add random indexes indefinitely","Remove WHERE"]', 0, 'Performance tuning should use the execution plan and workload evidence rather than assuming index usage alone is sufficient.', '["performance","execution-plan"]');

-- Verification query: should return 10 for every language/level pair.
SELECT `language`, `level`, COUNT(*) AS `count` FROM `questions` GROUP BY `language`, `level` ORDER BY `language`, `level`;
