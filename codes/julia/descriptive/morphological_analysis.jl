using QuranTree
using Makie
using CairoMakie
using MakieThemes

crps, tnzl = load(QuranData());
crpstbl = table(crps)
tnzltbl = table(tnzl)

