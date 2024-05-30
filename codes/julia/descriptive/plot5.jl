using CSV
using Colors
using DataFrames
using Distributions
using QuranTree
using Yunir
using Makie
using CairoMakie
using MakieThemes
using HTTP
using StatsBase
using Random

CairoMakie.activate!(type = "svg")
active_theme = :dust

if active_theme == :earth
    Makie.set_theme!(ggthemr(:earth))
    current_theme = Dict(
        :background => "#36312C",
        :text       => ["#555555", "#F8F8F0"],
        :line       => ["#ffffff", "#827D77"],
        :gridline   => "#504940",
        :swatch     => ["#F8F8F0", "#DB784D", "#95CC5E", "#E84646", "#F8BB39", "#7A7267", "#E1AA93", "#168E7F", "#2B338E"],
        :gradient   => ["#7A7267", "#DB784D"]
    )
elseif active_theme == :dust
    Makie.set_theme!(ggthemr(:dust))
    current_theme = Dict(
        :background => "#FAF7F2",
        :text       => ["#5b4f41", "#5b4f41"],
        :line       => ["#8d7a64", "#8d7a64"],
        :gridline   => "#E3DDCC",
        :swatch     => ["#555555", "#db735c", "#EFA86E", "#9A8A76", "#F3C57B", "#7A6752", "#2A91A2", "#87F28A", "#6EDCEF"],
        :gradient   => ["#F3C57B", "#7A6752"]
    )
else
    error("No active_theme=" * string(active_theme))
end;
colors = [parse(Color, i) for i in current_theme[:swatch]]
colors
crps, tnzl = load(QuranData());
crpstbl = table(crps)

qrn_order_url = "https://raw.githubusercontent.com/alstat/QuranData/main/revelation_order.txt"
http_response = HTTP.get(qrn_order_url)
quran_order = DataFrame(CSV.File(http_response.body, header=true, delim="\t"))
quran_order |> show


# plot 3
# for boxplot
word_len = combine(
    groupby(crpstbl.data, [:chapter, :verse]),
    :word => x -> length(unique(x))
);
word_len

ayah_len = combine(
    groupby(word_len, :chapter),
    :word_function => x -> Ref(vcat(x))
);
ayah_len
xs = Int64[]; j = 1
for i in ayah_len[!,:chapter]
    xs = vcat(xs, repeat([i], inner=length(ayah_len[j,:word_function_function])))
    j += 1
end
ys = vcat(ayah_len[!,:word_function_function]...);
place_rev = string.(sort(quran_order, :Number)[!,:Type]);
colors = [parse(Color, i) for i in current_theme[:swatch]]

place_rev_order = string.(quran_order[!,:Type]);
colors_rev_order = [parse(Color, i) for i in current_theme[:swatch]]
ayah_len[!,"location"] = place_rev;

ayah_len[!,"location"] = place_rev;

word_loc = []
for i in word_len[!,:chapter]
    push!(word_loc, place_rev[i])
end

word_len[!,:location] = word_loc
word_len_meccan = word_len[word_len[!,:location] .== "Meccan",:]

Random.seed!(123)
unif_sampling = word_len_meccan[sample(1:size(word_len_meccan,1), 250), :word_function]
# dist_sampling = sample(word_len_meccan[!,:word_function], 500)

f = Figure(resolution=(500,500))
ax1 = Axis(f[1, 1], ylabel="Population")
ax2 = Axis(f[2, 1], xlabel="Meccan Word Count per Ayah", ylabel="Sample")
# ax3 = Axis(f[3, 1], xlabel="Word Count per Ayah", ylabel="Weighted Sampling")
hist!(ax1, word_len_meccan[!,:word_function], normalization=:pdf, bins=50)
hist!(ax2, unif_sampling, normalization=:pdf, bins=15)
# hist!(ax3, dist_sampling, normalization=:pdf, bins=15)
density!(ax1, word_len[!,:word_function], color = (current_theme[:swatch][3], 0.5), strokecolor=(current_theme[:swatch][5], 0.8), strokewidth=3)
density!(ax2, unif_sampling, color = (current_theme[:swatch][3], 0.5), strokecolor=(current_theme[:swatch][5], 0.8), strokewidth=3)
# density!(ax3, dist_sampling, color = (current_theme[:swatch][3], 0.5), strokecolor=(current_theme[:swatch][5], 0.8), strokewidth=3)
linkaxes!(ax1, ax2)

hidedecorations!(ax1, grid=false, label=false)
hideydecorations!(ax2, grid=false, label=false)
# hideydecorations!(ax3, grid=false, label=false)
labels = ["Histogram", "Kernel Density Estimate"]
elements = [PolyElement(polycolor = colors[[2,3]][i]) for i in 1:length(labels)]
title = ""

axislegend(ax1, elements, labels, title, orientation=:vertical, halign=:right)
f
save("plots/plot5.pdf", f)

# population statistics
mean(word_len_meccan[!,:word_function];)
median(word_len_meccan[!,:word_function])
var(word_len_meccan[!,:word_function]; corrected=false)
std(word_len_meccan[!,:word_function]; corrected=false)

# sample statistics
mean(unif_sampling)
median(unif_sampling)
var(unif_sampling)
std(unif_sampling)

# prob(X<=10)

word_len_meccan[!,:word_function][word_len_meccan[!,:word_function] .== 35]
length(word_len_meccan[!,:word_function])
unif_sampling[unif_sampling .== 35]
unif_sampling[unif_sampling .== 1] / length(unif_sampling)

5/4613