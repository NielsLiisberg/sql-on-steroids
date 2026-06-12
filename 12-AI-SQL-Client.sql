-- This is what we will play with
values sqlxxl.ask_ai  (
    question  => 'tell me a joke'
);

-- and we need a litte trace table to see the payloads we send to the ai and the responses we get back.
create or replace  table sqlxxl.trace (
    id int generated always as identity,
    text clob,
    created_at timestamp default current_timestamp
);


-- To acces open api you need to set the endpoint, model and key. 
-- You can get a free key from openai.com and use any of the models listed on their website.
-- https://platform.openai.com/api-keys
create or replace variable sqlxxl.ai_endpoint   varchar(256)  default 'https://api.openai.com/v1/responses';
create or replace variable sqlxxl.ai_key        varchar(2560) default '...Your open AI key goes here...'; 
create or replace variable sqlxxl.ai_model      varchar(256)  default 'gpt-5-mini';

-- Now what do we have:
values (
    sqlxxl.ai_model, 
    sqlxxl.ai_key, 
    sqlxxl.ai_endpoint
);

-- does it work ? It will complan Missing bearer or basic authentication in header, but at least we know we can reach the endpoint from our IBM i
values qsys2.http_get  (
    url  => sqlxxl.ai_endpoint  -- from config, can be local or hosted
);

----------------------------------------------------------------
-- Now the magic !!
----------------------------------------------------------------
create or replace function  sqlxxl.ask_ai (
    question            clob,
    instructions        clob default 'Answers as an assistant'
 )
returns clob

    specific ASKAI 
    language sql
    modifies sql data
    set option output=*print, commit=*none, dbgview=*source
    
begin 

    declare answer clob;
    declare header clob; 
    declare payload clob; 
    declare response clob;

    -- We send requestion in JSON format, header is required
    set header = json_object ( 
        'sslTolerate' : 'true',
        'headers' : json_object ( 
            'Content-Type'  : 'application/json;charset=UTF-8',
            'Authorization' : 'Bearer ' || sqlxxl.ai_key ABSENT ON NULL
        ) 
    ); 

    -- The payload has two of our components, system instructions and the question. (and the model) 
    -- the rest is meta data to control the response, you can experiment with it to see how it changes the answer.
    -- The format of the payload is different between providers, for olama we can send the question and instructions in a messages array, but for open ai we need to send them as separate fields.
    set payload = json_object ( 
        'model'    : sqlxxl.ai_model,
        'reasoning': json_object (
            'effort': 'low'
        ),
        'stream'   : 'false' format json, -- we want the response all at once, not in a stream
        'max_output_tokens': int(10000),
        'instructions': instructions,
        'input'    : question
    );

    -- Let's log the header and payload we send to the ai, this is useful for debugging and to see what we are sending to the ai. 
    insert into  sqlxxl.trace (text) values( header);
    insert into  sqlxxl.trace (text) values( payload);
    
    -- Now we send the request to the ai, we use http_post to send the request and get the response.
    set response  = qsys2.http_post (
        url             => sqlxxl.ai_endpoint , -- from config, can be local or hosted
        options         => header , 
        request_message => payload
    );

    -- The format of the response is different between providers and models, so we need to extract the answer from the response.
    insert into  sqlxxl.trace (text) values(response);

    -- Use OLAP to wrangel the response, we need to do this because the format of the response is different between models and providers.
    -- For olama we can get the answer directly from $.message.content, but for open ai we need to extract the text from the output array.
    -- And we need one single text string, so we use listagg to concatenate the text from the output array into one string.  
    Select listagg (ifnull(content_text,'') , ' ') within group (order by ord)
        into answer
        from json_table (
            response ,
            'lax $.output[*].content[*]' 
            columns (             
                content_text  clob  path '$.text',
                ord for ordinality -- "ordinality" is a "build in". We need this to maintain the order of the text in the output array, otherwise we might get a jumbled answer
            )
        )
        where content_text is not null;

    if answer is null then
        insert into  sqlxxl.trace (text) values(response);
        return response; -- return the json with the error 
    end if; 

    return answer; 
    
end;    


-- test the function with a simple question, you can change the question and instructions as you like.
values sqlxxl.ask_ai  (
    question  => 'if a,b and c are cities. and i can drive from a to b and from b to c. Can i drive from a to c ?'
);

-- Now with instructions:
values sqlxxl.ask_ai  (
    instructions => 'Talk like a pirate',
    question  => 'tell a sailor joke'
);

-- So what do we have in our trace:
select * from sqlxxl.trace a order by rrn(a) desc ;


-- Do you remember the in_box table from out demo schema?
-- the inbox. Now let's build a function that takes a question and instructions 
-- as input, sends it to the ai and returns the answer. 
-- We will use the http_post function to send the request to the ai and get the response. 
-- The format of the request and response is different between providers, so we need to wrangle it a bit to get the answer. 
select * from sqlxxl.in_tray;

values sqlxxl.ask_ai  (
    instructions => 'The database is: Db2 for i. respond SQL always in lowercase.' ,
    question  => '
        create or replace an sql view that shows an resume of the inbox table. 
        the inbox is named sqlxxl.in_tray. 
        and has the following columns: SOURCE, SUBJECT, NOTE_TEXT.
        the sql UDF that call the AI is sqlxxl.ask_ai and it takes two parameters, instructions and question.' 
);

create or replace view sqlxxl.in_tray_resume as
select
  source,
  subject,
  sqlxxl.ask_ai('summarize the following note in one concise sentence', note_text) as note_summary
from sqlxxl.in_tray;

select * from sqlxxl.in_tray_resume;


create or replace view sqlxxl.in_tray_resume as
select
  source,
  subject,
  sqlxxl.ask_ai(
    'summarize the following inbox message in one concise sentence. preserve any named entities and important actions. if the message is empty, return an empty string.',
    'subject: ' || coalesce(subject,'') || '; note: ' || coalesce(note_text,'')
  ) as resume
from sqlxxl.in_tray;

select * from sqlxxl.in_tray_resume;

-- the response is:
create or replace view sqlxxl.in_tray_resume as
select
  source,
  subject,
  sqlxxl.ask_ai(
    'summarize the following note in one concise sentence. be neutral and keep it to one sentence.',
    note_text
  ) as summary
from sqlxxl.in_tray;

-- does it work?
select * from sqlxxl.in_tray_resume;

values sqlxxl.ask_ai  (
    instructions => 'The database is: Db2 for i. respond SQL always in lowercase.' ,
    question  => '
        construct or replace an sql view based on the table sqlxxl.in_tray.
        the sqlxxl.in_tray table has the following columns: SOURCE, SUBJECT, NOTE_TEXT.
        The view shows the source, subject and note_text, an sort summary of NOTE_TEXT call SUMMARY.
        additional a column named SENTIMENT that shows the sentiment of the note_text with the exact values of positive, negative or neutraL. 
        the sql UDF that call the AI is sqlxxl.ask_ai and it takes two parameters, instructions and question.'
);
 
-- the response is:
create or replace view sqlxxl.in_tray_view as
select
  source,
  subject,
  note_text,
  sqlxxl.ask_ai('summarize the following note in one concise sentence', note_text) as summary,
  case
    when lower(trim(sqlxxl.ask_ai('classify the sentiment of the following note as positive, negative, or neutral and return only one of these exact words: positive, negative, or neutral', note_text))) in ('positive','negative','neutral')
      then lower(trim(sqlxxl.ask_ai('classify the sentiment of the following note as positive, negative, or neutral and return only one of these exact words: positive, negative, or neutral', note_text)))
    else 'neutral'
  end as sentiment
from sqlxxl.in_tray;

select * from sqlxxl.in_tray_view;


create or replace view sqlxxl.in_tray_ai_view as
select
  source,
  subject,
  note_text,
  sqlxxl.ask_ai(
    'summarize the following text in one short sentence',
    note_text
  ) as summary,
  sqlxxl.ask_ai(
    'determine the sentiment of the following text. return exactly one of: positive, negative, neutral. return only that single word with no extra punctuation or explanation',
    note_text
  ) as sentiment
from sqlxxl.in_tray;

select  * from sqlxxl.in_tray_ai_view;

-- now it's getting more interesting, now AI is using it self in the query  
-- this is the response: 
create or replace view sqlxxl.in_tray_view as
select
  source,
  subject,
  note_text,
  cast(sqlxxl.ask_ai(
    'provide a concise summary (one short sentence or phrase, no more than 120 characters) of the following text.',
    note_text
  ) as varchar(240)) as summary,
  lower(cast(sqlxxl.ask_ai(
    'analyze the sentiment of the following text and return exactly one of these three words: positive, negative, neutral. do not return anything else, no punctuation, no explanation.',
    note_text
  ) as varchar(20))) as sentiment
from sqlxxl.in_tray;

-- does it work ? 
select * from sqlxxl.in_tray_view;


-- Integrate this in RPG? 
-- The code is provided in the "Utilities" folder: 
**free                                                                             
ctl-opt copyright('System & Method (C), 2019-2026');                               
ctl-opt decEdit('0,') datEdit(*YMD.) main(main);                                   
ctl-opt option(*nodebugio:*srcstmt:*nounref);                                      
// -----------------------------------------------------------------------------   
// Integrating ASK_AI into RPGLE                                                   
// -----------------------------------------------------------------------------   
dcl-proc main;                                                                     
                                                                                   
    dcl-s question   varchar(32000);                                               
    dcl-s instructions  varchar(32000);                                            
    dcl-s answer       varchar(32000);                                             
                                                                                   
    question = 'What is the meaning of life?';                                     
    instructions = 'Answer the question in a concise manner.';                     
                                                                                   
    exec sql set :answer = sqlxxl.ask_ai(:question, :instructions);                
                                                                                   
    snd-msg *info answer;                                                          
            
end-proc;   


