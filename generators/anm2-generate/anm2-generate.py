import_file = "template.anm2"

layer = ("head0", "head1", "head2", "head3", "head4", "head5")

with open(import_file) as f:
    original = f.readlines()

    
for i in range(1, 7):
    for j in range(0, 351, 10):
        with open("lock_{}_{}.anm2".format(i, j), "w") as k:
            export_file = [line.format(id=i, hue=j, name=layer[i-1]) for line in original]
            k.writelines(export_file)

