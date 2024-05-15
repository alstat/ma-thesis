using CSV
using Colors
using DataFrames
using QuranTree
using Yunir
using Makie
using CairoMakie
using MakieThemes
using HTTP

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

crps, tnzl = load(QuranData());
crpstbl = table(crps)

qrn_order_url = "https://raw.githubusercontent.com/alstat/QuranData/main/revelation_order.txt"
http_response = HTTP.get(qrn_order_url)
quran_order = DataFrame(CSV.File(http_response.body, header=true, delim="\t"))
quran_order |> show

# for barplot
ayah_freq = combine(
    groupby(crpstbl.data, :chapter),
    :verse => x -> length(unique(x))
);

mean(ayah_freq[!,:verse_function])
median(ayah_freq[!,:verse_function])
std(ayah_freq[!,:verse_function])

# for boxplot
word_len = combine(
    groupby(crpstbl.data, [:chapter, :verse]),
    :word => x -> length(unique(x))
);

ayah_len = combine(
    groupby(word_len, :chapter),
    :word_function => x -> Ref(vcat(x))
);
word_freq = DataFrame(
    chapter=ayah_len[!,:chapter],
    word_function=sum.(ayah_len[!,:word_function_function])
);
mean(word_freq[!,:word_function])
median(word_freq[!,:word_function])
std(word_freq[!,:word_function])


word_freq
xs = Int64[]; j = 1
for i in ayah_len[!,:chapter]
    xs = vcat(xs, repeat([i], inner=length(ayah_len[j,:word_function_function])))
    j += 1
end
ys = vcat(ayah_len[!,:word_function_function]...);
ys
place_rev = string.(sort(quran_order, :Number)[!,:Type]);
colors = [parse(Color, i) for i in current_theme[:swatch]]

place_rev_order = string.(quran_order[!,:Type]);
colors_rev_order = [parse(Color, i) for i in current_theme[:swatch]]

xs_color = Int64[]; j=1
for i in place_rev
    xs_color = vcat(xs_color, repeat([i], inner=length(ayah_len[j, :word_function_function])))
    j += 1
end

f = Figure(resolution=(800, 700));
xticks = vcat(1, 19:19:114...)
grd = f[1,1] = GridLayout()
gax = grd[1,1:30] = GridLayout()
max = grd[1,31:33] = GridLayout()
ax_bar = Axis(
    gax[1,1], ylabel="Ayah Count",
    xticks=(xticks, string.(xticks))
)
ax_barhist = Axis(max[1,2:7])
ax_barbox = Axis(max[1,1])
wx_bar = Axis(
    gax[2,1], ylabel="Word Count",
    xticks=(xticks, string.(xticks)),
    yticks=([0, 2500, 5000], ["0", "2.5k", "5.0k"])
)
wx_barhist = Axis(max[2,2:7])
wx_barbox = Axis(max[2,1])
ax_box = Axis(
    gax[3,1], xlabel="Surah", ylabel="Word Count Per Ayah",
    xticks=(xticks, string.(xticks))
)
ax_boxhist = Axis(max[3,2:7])
ax_boxbox = Axis(max[3,1])

barplot!(ax_bar, ayah_freq.chapter, ayah_freq.verse_function, color=colors[[2,4]][indexin(place_rev, ["Meccan", "Medinan"])], label="Meccan")
hidexdecorations!(ax_bar, grid=false)
surah_numbers = ayah_freq.chapter[ayah_freq.verse_function .> 180][[1,3:end...]]
surah_heights = [290, 210, 230, 185]; i = 1
for surah in surah_numbers
    surah_name = chapter_name(crpstbl[surah], lang=:english)
    surah_labels = string("  (", surah, ") ", surah_name)
    text!(ax_bar,  surah_labels, position=(surah, surah_heights[i]),
        fontsize=12, align=(:left, :top))
    i += 1
end
density!(ax_barhist, ayah_freq.verse_function, direction=:y,
    color=colors[5])
hidedecorations!(ax_barhist)
hidespines!(ax_barhist)
boxplot!(ax_barbox, repeat([1], inner=length(ayah_freq.verse_function)),
    ayah_freq.verse_function, color=colors[3], mediancolor=colors[6],
    whiskercolor=colors[6], width=0.1, markersize=4, gap=0.3);
hidedecorations!(ax_barbox)
hidespines!(ax_barbox)
ylims!(ax_bar, low=-40, high=310)
ylims!(ax_barbox, low=-40, high=310)
ylims!(ax_barhist, low=-40, high=310)
linkyaxes!(ax_bar, ax_barbox, ax_barhist)

barplot!(wx_bar, word_freq.chapter, word_freq.word_function,
    color=colors[[2,4]][indexin(place_rev, ["Meccan", "Medinan"])])
hidexdecorations!(wx_bar, grid=false)
arrows!(wx_bar, [26], [1100], [2], [1230], color=current_theme[:line][1])
arrows!(wx_bar, [37], [700], [2], [950], color=current_theme[:line][1])
surah_numbers = [2, 7, 26, 37]
surah_heights = [6300, 3500, 3300, 2600]; i = 1
for surah in surah_numbers
    surah_name = chapter_name(crpstbl[surah], lang=:english)
    surah_labels = string("  (", surah, ") ", surah_name)
    text!(wx_bar,  surah_labels, position=(surah, surah_heights[i]),
        fontsize=12, align=(:left, :top))
    i += 1
end
density!(wx_barhist, word_freq.word_function, direction=:y,
    color=colors[5])
hidedecorations!(wx_barhist)
hidespines!(wx_barhist)
boxplot!(wx_barbox, repeat([1], inner=length(word_freq.word_function)),
    word_freq.word_function, color=colors[3], mediancolor=colors[6],
    whiskercolor=colors[6], width=0.1, markersize=4, gap=0.3);
hidedecorations!(wx_barbox)
hidespines!(wx_barbox)
ylims!(wx_bar, low=-900, high=7000)
ylims!(wx_barbox, low=-900, high=7000)
ylims!(wx_barhist, low=-900, high=7000)
linkyaxes!(wx_bar, wx_barbox, wx_barhist)

boxplot!(ax_box, xs, ys, width=1.2, markersize=4, gap=0.3,
    color=colors[[2,4]][indexin(xs_color, ["Meccan", "Medinan"])], whiskercolor=colors[5], mediancolor=colors[5]);
density!(ax_boxhist, ys, direction=:y,
    color=colors[5])
hidedecorations!(ax_boxhist)
hidespines!(ax_boxhist)
boxplot!(ax_boxbox, repeat([1], inner=length(ys)), ys, color=colors[3],
    mediancolor=colors[6], whiskercolor=colors[6], width=0.1,
    markersize=4, gap=0.3);
hidedecorations!(ax_boxbox)
hidespines!(ax_boxbox)
linkyaxes!(ax_box, ax_boxbox, ax_boxhist)

rowgap!(gax, 10)
colgap!(max, 1)
rowgap!(max, 10)
colgap!(grd, 5)

labels = ["Meccan", "Medinan"]
elements = [PolyElement(polycolor = colors[[2,4]][i]) for i in 1:length(labels)]
title = "Groups"

axislegend(ax_bar, elements, labels, title, orientation=:vertical)

ayah_word_freq = DataFrame(xs = xs, ys = ys)
word_means = combine(
    groupby(ayah_word_freq, :xs),
    :ys => x -> mean(x)
);
mean(word_means[!,:ys_function])
median(word_means[!,:ys_function])
std(word_means[!,:ys_function])

save("plots/plot1.pdf", f)

# plot 2
# for barplot
ayah_freq = combine(
    groupby(crpstbl.data, :chapter),
    :verse => x -> length(unique(x))
);
# for boxplot
word_len = combine(
    groupby(crpstbl.data, [:chapter, :verse]),
    :word => x -> length(unique(x))
);
ayah_len = combine(
    groupby(word_len, :chapter),
    :word_function => x -> Ref(vcat(x))
);
word_freq = DataFrame(
    chapter=ayah_len[!,:chapter],
    word_function=sum.(ayah_len[!,:word_function_function])
);
xs = Int64[]; j = 1
for i in ayah_len[!,:chapter]
    xs = vcat(xs, repeat([i], inner=length(ayah_len[j,:word_function_function])))
    j += 1
end
ys = vcat(ayah_len[!,:word_function_function]...);
ayah_len[!,"location"] = place_rev;
ayah_len |> show

# quranic revelation order
ayah_freq_ordered = ayah_freq[quran_order[!, :Number],:];
word_freq_ordered = word_freq[quran_order[!, :Number],:];
ayah_len_ordered = ayah_len[quran_order[!, :Number],:];

xs_color_ordered = Int64[]; j=1
for i in ayah_len_ordered[!,:location]
    xs_color_ordered = vcat(xs_color_ordered, repeat([i], inner=length(ayah_len_ordered[j, :word_function_function])))
    j += 1
end

xs_ordered = Int64[]; j = 1
for i in ayah_len[!,:chapter] # we don't use the ordered because boxplot x axis always sorted
    xs_ordered = vcat(xs_ordered, repeat([i], inner=length(ayah_len_ordered[j,:word_function_function])))
    j += 1
end
ys_ordered = vcat(ayah_len_ordered[!,:word_function_function]...);

f = Figure(resolution=(800, 700));
xticks = vcat(1, 19:19:114...)
xticks_lab = string.(vcat(96, ayah_freq_ordered.chapter[19:19:114]))
grd = f[1,1] = GridLayout()
gax = grd[1,1:30] = GridLayout()
max = grd[1,31:33] = GridLayout()
ax_bar = Axis(
    gax[1,1], ylabel="Ayah Count",
    xticks=(xticks, string.(xticks))
)
ax_barhist = Axis(max[1,2:7])
ax_barbox = Axis(max[1,1])
wx_bar = Axis(
    gax[2,1], ylabel="Word Count",
    xticks=(xticks, string.(xticks)),
    yticks=([0, 2500, 5000], ["0", "2.5k", "5.0k"])
)
wx_barhist = Axis(max[2,2:7])
wx_barbox = Axis(max[2,1])
ax_box = Axis(
    gax[3,1], xlabel="Surah's Order of Revelation", ylabel="Word Count Per Ayah",
    xticks=(xticks, string.(xticks_lab))
)
ax_boxhist = Axis(max[3,2:7])
ax_boxbox = Axis(max[3,1])

barplot!(ax_bar, 1:length(ayah_freq_ordered.chapter), ayah_freq_ordered.verse_function,
    color=colors_rev_order[[2,4]][indexin(place_rev_order, ["Meccan", "Medinan"])])
hidexdecorations!(ax_bar, grid=false)
arrows!(ax_bar, quran_order[quran_order[!,:Number] .== 7,:Order][1], [195],
    [2], [40], color=current_theme[:line][1])
surah_numbers = [2, 7, 26, 37]
surah_heights = [290, 280, 230, 185]; i = 1
for surah in surah_numbers
    surah_name = chapter_name(crpstbl[surah], lang=:english)
    surah_labels = string("  (", surah, ") ", surah_name)
    surah_pos = quran_order[quran_order[!,:Number] .== surah,:Order][1]
    text!(ax_bar,  surah_labels, position=(surah_pos, surah_heights[i]),
        fontsize=12, align=(:left, :top))
    i += 1
end
density!(ax_barhist, ayah_freq_ordered.verse_function, direction=:y,
    color=colors[5])
hidedecorations!(ax_barhist)
hidespines!(ax_barhist)
boxplot!(ax_barbox, repeat([1], inner=length(ayah_freq_ordered.verse_function)),
    ayah_freq_ordered.verse_function, color=colors[3], whiskercolor=colors[6],
    mediancolor=colors[6], width=0.1, markersize=4, gap=0.3);
hidedecorations!(ax_barbox)
hidespines!(ax_barbox)
ylims!(ax_bar, low=-40, high=310)
ylims!(ax_barbox, low=-40, high=310)
ylims!(ax_barhist, low=-40, high=310)
linkyaxes!(ax_bar, ax_barbox, ax_barhist)

barplot!(wx_bar, 1:length(word_freq_ordered.chapter), word_freq_ordered.word_function,
    color=colors_rev_order[[2,4]][indexin(place_rev_order, ["Meccan", "Medinan"])])
hidexdecorations!(wx_bar, grid=false)
arrows!(wx_bar, quran_order[quran_order[!,:Number] .== 7,:Order][1], [3100],
    [2], [900], color=current_theme[:line][1])
arrows!(wx_bar, quran_order[quran_order[!,:Number] .== 26,:Order][1], [1100],
    [2], [1700], color=current_theme[:line][1])
arrows!(wx_bar, quran_order[quran_order[!,:Number] .== 37,:Order][1], [700], [2], [950], color=current_theme[:line][1])
surah_numbers = [2, 7, 26, 37]
surah_heights = [6300, 5000, 3800, 2600]; i = 1
for surah in surah_numbers
    surah_name = chapter_name(crpstbl[surah], lang=:english)
    surah_labels = string("  (", surah, ") ", surah_name)
    surah_pos = quran_order[quran_order[!,:Number] .== surah,:Order][1]
    text!(wx_bar,  surah_labels, position=(surah_pos, surah_heights[i]),
        fontsize=12, align=(:left, :top))
    i += 1
end
density!(wx_barhist, word_freq_ordered.word_function, direction=:y,
    color=colors[5])
hidedecorations!(wx_barhist)
hidespines!(wx_barhist)
boxplot!(wx_barbox, repeat([1], inner=length(word_freq_ordered.word_function)),
    word_freq_ordered.word_function, color=colors[3], whiskercolor=colors[6],
    mediancolor=colors[6], width=0.1, markersize=4, gap=0.3);
hidedecorations!(wx_barbox)
hidespines!(wx_barbox)
ylims!(wx_bar, low=-900, high=7000)
ylims!(wx_barbox, low=-900, high=7000)
ylims!(wx_barhist, low=-900, high=7000)
linkyaxes!(wx_bar, wx_barbox, wx_barhist)

boxplot!(ax_box, xs_ordered, ys_ordered, width=1.2, markersize=4, gap=0.3,
    color=colors[[2,4]][indexin(xs_color_ordered, ["Meccan", "Medinan"])], whiskercolor=colors[5], mediancolor=colors[5]);
density!(ax_boxhist, ys_ordered, direction=:y,
    color=colors[5])
hidedecorations!(ax_boxhist)
hidespines!(ax_boxhist)
boxplot!(ax_boxbox, repeat([1], inner=length(ys_ordered)), ys_ordered,
    color=colors[3], whiskercolor=colors[6], mediancolor=colors[6], width=0.1,
    markersize=4, gap=0.3);
hidedecorations!(ax_boxbox)
hidespines!(ax_boxbox)
linkyaxes!(ax_box, ax_boxbox, ax_boxhist)

rowgap!(gax, 10)
colgap!(max, 1)
rowgap!(max, 10)
colgap!(grd, 5)

labels = ["Meccan", "Medinan"]
elements = [PolyElement(polycolor = colors[[2,4]][i]) for i in 1:length(labels)]
title = "Groups"

axislegend(ax_bar, elements, labels, title, orientation=:vertical, halign=:left)

save("plots/plot2.pdf", f)

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
ayah_len[!,"location"] = place_rev;
ayah_len_loc = combine(groupby(ayah_len, :location),
    :word_function_function => x -> Ref(vcat(x...))
)
category_labels = vcat(
    repeat([ayah_len_loc[1,:location]], inner=length(ayah_len_loc[1,2])),
    repeat([ayah_len_loc[2,:location]], inner=length(ayah_len_loc[2,2]))
);
f = Figure(resolution=(500, 500));
rainclouds!(Axis(
    f[1, 1], xlabel="Word Count per Ayah",
    yticks=(1:0.5:2.5, ["Meccan", "", "Medinan", ""])
    ), category_labels, data_array;
    orientation=:horizontal,
    plot_boxplots = true, cloud_width=0.5, clouds=hist, hist_bins=50,
    color = colors[[1,3]][indexin(category_labels, unique(category_labels))],
    whiskercolor=colors[4], mediancolor=colors[4])
    
f
save("plots/plot3.pdf", f)
