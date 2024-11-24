# Installation

In this section, we’ll walk you through the steps needed to get MIMIQ up and running on your system. We’ll cover everything from installing Julia, adding the necessary registries, and installing the MIMIQ packages, to setting up Jupyter with a Julia kernel for an enhanced coding experience. By the end of this guide, you’ll be ready to dive into quantum computing with MIMIQ.

- [Installation](#installation)
  - [Installing Julia](#installing-julia)
    - [Install `juliaup`](#install-juliaup)
      - [Windows](#windows)
      - [macOS and Linux](#macos-and-linux)
    - [Install Julia](#install-julia)
  - [Adding the QPerfect Registry](#adding-the-qperfect-registry)
  - [Installing MIMIQ](#installing-mimiq)
  - [Using MIMIQ and Julia with Jupyter](#using-mimiq-and-julia-with-jupyter)
    - [Install Jupyter](#install-jupyter)
    - [Start Jupyter](#start-jupyter)
    - [Using MIMIQ in Jupyter](#using-mimiq-in-jupyter)


## Installing Julia

To get started with MIMIQ, you will need to have Julia installed on your system. Julia is a high-level, high-performance programming language for technical computing.
We recommend using **juliaup** for an easy and streamlined installation process.

**juliaup** is a Julia version manager that simplifies the installation and management of Julia versions on your system. It allows you to easily switch between different versions of Julia, ensuring you always have the right version for your project.

To install Julia using **juliaup**, follow these steps:

### Install `juliaup`

#### Windows

On windows, you can install juliaup from the Microsoft Store.

#### macOS and Linux

On macOS and Linux, you can install juliaup using the following command in your terminal:

```sh
curl -fsSl https://install.julialang.org | sh
```

###  Install julia

Once `juliaup` is installed, you can install the latest stable version of Julia by running:

```sh
juliaup add release
```

For more detailed instructions on installing juliaup, refer to [juliaup's installation guide](https://github.com/julialang/juliaup#installation), and for more information and alternative methods for installing Julia, refer to the [official Julia website](https://julialang.org/).


## Adding the QPerfect Registry

Before you can install MIMIQ, you need to add the QPerfect registry. This step is crucial as it allows you to access the MIMIQ packages, released by QPerfect.

To add the QPerfect registry, open your [Julia REPL](https://docs.julialang.org/en/v1/stdlib/REPL/) and enter the package mode by pressing the `]` key. Then run the following command:

```julia
(@v1.11)> registry add General
(@v1.11)> registry add https://github.com/qperfect-io/QPerfectRegistry.git
```

Alternatively, from the Julia REPL, without switching to package mode, you can run the following command:

```julia
import Pkg
Pkg.Registry.add("General")
Pkg.Registry.add(RegistrySpec(url="https://github.com/qperfect-io/QPerfectRegistry.git"))
```

!!! note
    If this is your first time running Julia, adding the QPerfect registry will prevent Julia from adding the default General registry automatically.

## Installing MIMIQ

Once the QPerfect registry is added, you can install the `MimiqCircuits` package. This package is essential for using the MIMIQ framework for simulating quantum circuits.
Run the following command in your Julia REPL, in package mode:

```julia
(@v1.11)> add MimiqCircuits
```

Alternatively, you can run the following command without switching to package mode:

```julia
using Pkg
Pkg.add("MimiqCircuits")
```

this will install the latest version of the MIMIQ package in your main [Julia environment](https://docs.julialang.org/en/v1/manual/code-loading/#Environments) (`(@v0.15)` in this case). You can follow the same steps to install the package in other environments if needed.

To test if the installation was successful, you can run the following command in your Julia REPL:

```julia
using MimiqCircuits
```

You are now ready to start using MIMIQ for simulating quantum circuits in Julia!

## Using MIMIQ and Julia with Jupyter

Jupyter is an open-source web application that allows you to create and share documents that contain live code, equations, visualizations and narrative text. It is an excellent tool for interactive computing often used in data analysis or other technical workflows.

To use MIMIQ and Julia within Jupyter, you will need to install Jupyter and set up the proper kernel. Here's how you can do it:

### Install Jupyter

Follow the [official Jupyter installation guide](https://jupyter.org/install) to install Jupyter on your system. The easiest way is to use `pip` from a working Python installation (`pip install notebook`)..

Install the Julia Jupyter kernel (`IJulia`). After installing Jupyter, you need to add the Julia kernel. Run the following commands in your Julia REPL in package mode:
```julia
(@v1.11)> add IJulia
```

or alternatively, without switching to package mode:

```julia
using Pkg
Pkg.add("IJulia")
```

### Start Jupyter

You can start Jupyter by running the following command in your terminal:

```sh
jupyter notebook
```

This will open Jupyter in your default web browser. As an alternative, you can run Jupyter directly from the Julia REPL by running:

```julia
using IJulia
notebook()
```

### Using MIMIQ in Jupyter

Now that you have Jupyter set up and  running with the Julia kernel, you can start using MIMIQ. Create a new notebook and select the Julia kernel. Then you can import and use MimiqCircuits as follows:

```julia
using MimiqCircuits
```

You are now ready to explore and experiment with MIMIQ in a Jupyter notebook.
