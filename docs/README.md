# How to generate documentation locally

When building the documentation of MimiqCircuits, the documentation of MimiqCircuitsBase and MimiqLink is also built.

Some parts of the documentation will require access to a remote service for MIMIQ-CIRC. Credentials for these services can be set as environment variables before building the documentation.

```
export MIMIQUSER="youruser@yourdomanin.com"
export MIMIQPASS="yourpassword"
```

Once the credentials have been set, the documentation can be built with the following commands:

```
cd docs

julia --project=. -e 'import Pkg; Pkg.develop(path="..")'

# optionally, if you are modifying MimiqCircuitsBase and MimiqLink locally
#julia --project=. -e 'import Pkg; Pkg.develop(path="path/to/local/MimiqCircuitsBase")'
#julia --project=. -e 'import Pkg; Pkg.develop(path="path/to/local/MimiqLink")'

julia --project=. make.jl
```

