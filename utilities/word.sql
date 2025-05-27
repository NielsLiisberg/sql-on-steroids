-- Word: 
-- returns the nth delimited word in string or returns null 
-- if fewer than n words are in string. The n must be a positive whole number
-- (C) Niels Liisberg 2020
------------------------------------------------------------------------------  
create or replace function sqlxxl.word (
    sourceString clob, 
    wordNumber int,
    delimiter char(1) default ' '
) 
returns clob 
set option output=*print, commit=*none, dbgview = *source --list
begin
  
    declare startPos  int;
    declare nextPos   int;
    declare wordCount int;
    declare sourceLen int;

    set nextPos = 0;
    set wordCount = 0 ;
    set sourceLen = length(sourceString);

    repeat 

        set startpos = nextPos + 1;
            
        -- trim until nonblank
        while substring (sourceString , startpos , 1) <= ' ' and startPos < sourceLen do
            set startpos = startpos +1;
        end while;
        
        -- White space delimiter? Do it the hard and slow way
        if delimiter <= ' ' then 
            set nextPos = startpos;
            while substring (sourceString , nextPos , 1) > ' ' and nextpos <= sourceLen do
                set nextPos = nextPos +1;
            end while;
        else 
            set nextPos = locate (delimiter , sourceString , startpos);
        end if;  
        
        set wordCount = wordCount +1;
        
        -- out of bounds ( No more delimiters but still ask for the next)
        if  nextPos < 1 and wordCount < wordNumber then 
            return null;
        end if;

    until wordCount >= wordNumber  
    end repeat;

    if  nextPos > 0 then
        return substring (sourceString , startpos , nextPos - startpos);
    else 
        return substring (sourceString , startpos );
    end if; 
  
end;
-- Usecases:
---------------------------------------------
values (
    sqlxxl.word(' a , b,c' , 1, ','),
    sqlxxl.word('a,b,c' , 2, ','),
    sqlxxl.word('a,b,c' , 3, ','),
    sqlxxl.word('a,b,c' ,99, ',')
);

values (
    sqlxxl.word('life is a gift' , 1),
    sqlxxl.word('life is a gift' , 2),
    sqlxxl.word('life is a gift' , 3),
    sqlxxl.word('life is a gift' , 4)
);

-- More realistic:
-- List disk usages (by the du command) 
-- take the first parm as KB and the next as filename
-- This uses the "bash" found elsewere on my gist
select 
    sqlxxl.word(element , 1) as kb ,
    sqlxxl.word(element , 2) as name
from table (
    systools.split (
        sqlxxl.bash ('cd /home;du -k') , 
        x'25'
    ) 
) a;     


