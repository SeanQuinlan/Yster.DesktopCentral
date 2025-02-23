# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.1.0] Unreleased

## [0.3.0] OTP Fixes + PS7 updates
Fixed the OTP code for codes sent via email.
Minor updates to make the code compatible with PowerShell v7.

## [0.4.0] Pagination
Updated main query function to paginate results depending on how many are requested.
The Endpoint Central API has recently been changed to only return a maximum of 1000 results per query. The previous default of "0" to return all results is no longer a valid amount, so I have implemented pagination of the results as a workaround. The default is still "0" but now the function will query 1000 at a time until it reaches all results.
