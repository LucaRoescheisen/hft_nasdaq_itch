N = 2048
with open("freelist_init.mem", "w") as f:
    for i in range(N):
        f.write(f"{i:03x}\n")




