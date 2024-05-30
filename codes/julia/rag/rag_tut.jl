# required dependencies to load the necessary extensions
using LinearAlgebra, SparseArrays 
using PromptingTools
using PromptingTools.Experimental.RAGTools
# to access unexported functionality
const RT = PromptingTools.Experimental.RAGTools

msg = aigenerate("Rewrite this sentence in a formal tone: {{sentence}}"; sentence="Hey, what's up?")
## Sample data
sentences = [
    "Search for the latest advancements in quantum computing using Julia language.",
    "How to implement machine learning algorithms in Julia with examples.",
    "Looking for performance comparison between Julia, Python, and R for data analysis.",
    "Find Julia language tutorials focusing on high-performance scientific computing.",
    "Search for the top Julia language packages for data visualization and their documentation.",
    "How to set up a Julia development environment on Windows 10.",
    "Discover the best practices for parallel computing in Julia.",
    "Search for case studies of large-scale data processing using Julia.",
    "Find comprehensive resources for mastering metaprogramming in Julia.",
    "Looking for articles on the advantages of using Julia for statistical modeling.",
    "How to contribute to the Julia open-source community: A step-by-step guide.",
    "Find the comparison of numerical accuracy between Julia and MATLAB.",
    "Looking for the latest Julia language updates and their impact on AI research.",
    "How to efficiently handle big data with Julia: Techniques and libraries.",
    "Discover how Julia integrates with other programming languages and tools.",
    "Search for Julia-based frameworks for developing web applications.",
    "Find tutorials on creating interactive dashboards with Julia.",
    "How to use Julia for natural language processing and text analysis.",
    "Discover the role of Julia in the future of computational finance and econometrics."
]
sources = map(i -> "Doc$i", 1:length(sentences))

## Build the index
index = build_index(sentences; chunker_kwargs=(; sources))

## Generate an answer
question = "What are the best practices for parallel computing in Julia?"

msg = airag(index; question) # short for airag(RAGConfig(), index; question)
## Output:
## [ Info: Done with RAG. Total cost: \$0.0
## AIMessage("Some best practices for parallel computing in Julia include us...