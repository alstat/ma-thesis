using QuranTree
using Yunir
using LinearAlgebra, SparseArrays 
using PromptingTools
using PromptingTools.Experimental.RAGTools
const RT = PromptingTools.Experimental.RAGTools

crps, tnzl = load(QuranData());
crps_dat = table(crps);
tnzl_dat = table(tnzl);

sentences = dediac.(verses(tnzl_dat[2]))

sources = map(i -> "Doc$i", 1:length(sentences))

## Build the index
index = build_index(sentences; chunker_kwargs=(; sources))

## Generate an answer
en_question = "Can you summarize what are the topics in this surah?"
question = aigenerate("Translate this to Arabic {{en_question}}."; en_question=en_question)
answer = airag(index; question=question.content)
aigenerate("Translate this to English {{ar_answer}}"; ar_answer=answer)

#########
sentences = [dediac.(verses(tnzl_dat[i])) for i in 1:5]

sources = map(i -> "Doc$i", 1:length(sentences))

## Build the index
index = build_index(sentences; chunker_kwargs=(; sources));

## Generate an answer
en_question = "Can you summarize what are the topics in this surah?"
question = aigenerate("Translate this to Arabic {{en_question}}."; en_question=en_question)
answer = airag(index; question=question.content)
aigenerate("Translate this to English {{ar_answer}}"; ar_answer=answer)


## Output:
## [ Info: Done with RAG. Total cost: \$0.0
## AIMessage("Some best practices for parallel computing in Julia include us...