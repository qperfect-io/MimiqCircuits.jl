#
# Copyright © 2023-2026 QPerfect. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#

# Smoke tests. The package is a thin wrapper around MimiqCircuitsBase
# and MimiqLink; the meaningful surface is remote execution, which
# cannot run in CI without credentials. These tests verify that the
# package loads, re-exports the core symbols, and that the cross-package
# constants stay in sync.
using Test
using MimiqCircuits
using MimiqCircuitsBase

@testset "MimiqCircuits" begin
    @testset "re-exports" begin
        @test isdefined(MimiqCircuits, :Circuit)
        @test isdefined(MimiqCircuits, :submit)
        @test isdefined(MimiqCircuits, :execute)
        @test isdefined(MimiqCircuits, :optimize)
        @test isdefined(MimiqCircuits, :MimiqConnection)
    end

    @testset "wire format" begin
        # MimiqCircuits must see the same WIRE_FORMAT_VERSION as
        # MimiqCircuitsBase; a drift here means the re-export chain is
        # broken.
        @test MimiqCircuits.WIRE_FORMAT_VERSION == MimiqCircuitsBase.WIRE_FORMAT_VERSION
        @test MimiqCircuits.WIRE_FORMAT_VERSION isa VersionNumber
    end
end
