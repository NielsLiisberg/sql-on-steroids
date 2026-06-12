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
                                                                                   
    exec sql set :answer = sqlr2r.ask_ai(:question, :instructions);                
                                                                                   
    snd-msg *info answer;                                                          
            
end-proc;   