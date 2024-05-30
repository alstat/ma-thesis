using Turing
using QuranTree
using Yunir
using TextAnalysis

data = QuranData();
crps, tnzl = load(data);
crps_data = table(crps);

function preprocess(s::String)
    feat = parse(QuranFeatures, s)
    disletters = isfeat(feat, AbstractDisLetters)
    prepositions = isfeat(feat, AbstractPreposition)
    particles = isfeat(feat, AbstractParticle)
    conjunctions = isfeat(feat, AbstractConjunction)
    pronouns = isfeat(feat, AbstractPronoun)
    adverbs = isfeat(feat, AbstractAdverb)

    return !disletters && !prepositions && !particles && !conjunctions && !pronouns && !adverbs
end

crps_tbl = filter(t -> preprocess(t.features), crps_data[18].data)

crps_new = deepcopy(crps_tbl)
feats = crps_new[!, :features]
feats = parse.(QuranFeatures, feats)
lemmas = lemma.(feats)
forms1 = crps_new[!, :form]
forms1[.!ismissing.(lemmas)] = lemmas[.!ismissing.(lemmas)]
crps_new[!, :form] = forms1
crps_new = CorpusData(crps_new)
lem_vrs = verses(crps_new)
vrs = normalize.(dediac.(lem_vrs))
crps1 = Corpus(StringDocument.(vrs))

update_lexicon!(crps1)
update_inverse_index!(crps1)
m1 = DocumentTermMatrix(crps1)

k = 4          # number of topics
iter = 1000    # number of gibbs sampling iterations
alpha = 0.1    # hyperparameter
beta = 0.1     # hyperparameter
ϕ, θ = lda(m1, k, iter, alpha, beta)
ntopics = 10
cluster_topics = Matrix(undef, ntopics, k);
for i = 1:k
    topics_idcs = sortperm(ϕ[i, :], rev=true)
    cluster_topics[:, i] = arabic.(m1.terms[topics_idcs][1:ntopics])
end

cluster_topics