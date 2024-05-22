using QuranTree

crps, tnzl = load(QuranData());
crpstbl = table(crps)

vrs = verses(crpstbl)


length(vrs)
split(vrs[2349], " ")[end][end-3:end-2]
vrs[2349]

# remove the disconnected letters
end_syllables = []
for i in 1:length(vrs)
    push!(end_syllables, split(vrs[i], " ")[end][end-3:end-2])
    @info i
end

vr