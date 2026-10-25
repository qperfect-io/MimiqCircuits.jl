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
        @test isdefined(MimiqCircuits, :QhiveConnection)
    end

    @testset "error reason" begin
        # The MIMIQ cloud and Quantum Hive report a failed job differently.
        @test MimiqCircuits._errorreason(Dict("errorMessage" => "boom")) == "boom"
        @test MimiqCircuits._errorreason(
            Dict("messages" => [Dict("message" => "boom"), Dict("message" => "bang")]),
        ) == "boom, bang"
        @test isnothing(MimiqCircuits._errorreason(Dict("status" => "ERROR")))
        @test isnothing(MimiqCircuits._errorreason(Dict("messages" => [])))
    end

    @testset "time limit" begin
        # Only the MIMIQ cloud reports per-user limits; every other connection,
        # such as Quantum Hive, gets the default.
        @test MimiqCircuits._gettimelimit(nothing) == MimiqCircuits.DEFAULT_TIME_LIMIT
        @test hasmethod(MimiqCircuits._gettimelimit, Tuple{QhiveConnection})
        @test hasmethod(MimiqCircuits._gettimelimit, Tuple{PlanqkConnection})
    end

    @testset "wire format" begin
        # MimiqCircuits must see the same WIRE_FORMAT_VERSION as
        # MimiqCircuitsBase; a drift here means the re-export chain is
        # broken.
        @test MimiqCircuits.WIRE_FORMAT_VERSION == MimiqCircuitsBase.WIRE_FORMAT_VERSION
        @test MimiqCircuits.WIRE_FORMAT_VERSION isa VersionNumber
    end
end
