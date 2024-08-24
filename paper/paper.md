---
title: 'ollamar: An R package for running large language models'
tags:
  - R
  - large language models
  - Ollama
  - natural language processing
  - artificial intelligence
authors:
  - name: Hause Lin
    orcid: 0000-0003-4590-7039
    affiliation: 1
  - name: Tawab Safi
    orcid: 0009-0000-5659-9890
    affiliation: 1
affiliations:
  - name: Massachusetts Institute of Technology, USA
    index: 1
date: 24 August 2024
bibliography: paper.bib
---

# Summary

Large language models (LLMs) have transformed natural language processing and AI. Many tools like Ollama (https://ollama.com/) have been developed to allow users to easily deploy and interact with LLMs hosted on  users' own machines. `ollamar` is an R library that interfaces with Ollama, allowing R users to easily run and interact with LLMs. This library is valuable for researchers and data scientists integrating LLMs into R workflows. `ollamar` is actively developed on GitHub (https://github.com/hauselin/ollamar) and available on the Comprehensive R Archive Network (https://cran.r-project.org/web/packages/ollamar/index.html).

# Statement of Need

The increasing importance of LLMs in various fields has created a demand for accessible tools that allow researchers and practitioners to leverage LLMs within their preferred programming environments. Locally deployed LLMs offer advantages in terms of data privacy, security, and customization, making them an attractive option for many users [@Chan2024Aug; @Liu2024Aug; @Lytvyn2024Jun; @Shostack2024Mar]. However, the lack of native R libraries for interfacing with locally deployed LLMs has limited the accessibility of these models to R users, even though R is a popular and crucial tool in statistics, data science, and various research domains [@Hill2024May; @Turner2024Aug]. `ollamar` fills a critical gap in the R ecosystem by providing a native interface to run locally deployed LLMs.

The `ollamar` R library is a package that integrates R with Ollama, allowing users to run large language models locally on their machines. Although alternative R libraries exist [@Gruber2024Apr], `ollamar` distinguishes itself through the features described below.

**User-friendly API wrapper**: It provides an interface to the Ollama server and all API endpoints, closely following the official API design. This design makes it easy for R users to understand how similar libraries (such as in Python and JavaScript) work while allowing users familiar with other programming languages to adapt to and use this library quickly. The consistent API structure across languages facilitates seamless transitions and knowledge transfer for developers working in multi-language environments.

**Consistent and flexible output formats**: All functions that call API endpoints return `httr2::httr2_response` objects by default, but users can specify different output formats, such as dataframes (`"df"`), lists (of JSON objects) (`"jsonlist"`), raw strings (`"raw"`), text vectors (`"text"`), or request objects (`"req"`). This flexibility greatly enhances the usability and versatility of the library. Users can choose the format that best suits their needs, such as when working with different data structures, integrating the output with other R packages, or allowing parallelization via the `httr2` library.

**Utility functions for managing conversation history**: LLM APIs often expect conversational or chat history data as input, often nested lists or JSON objects. Note that this data format is standard for chat-based applications and APIs (not limited to Ollama), such as those provided by OpenAI and Anthropic. `ollamar` provides helper functions to simplify preparing and processing conversational data for input to different LLMs, streamlining the workflow for chat-based applications.

# Conclusion

`ollamar` bridges a crucial gap in the R ecosystem by providing seamless access to large language models through Ollama. Its user-friendly API, flexible output formats, and conversation management utilities enable R users to integrate LLMs into their workflows easily. This library empowers researchers and data scientists across various disciplines to leverage the power of locally deployed LLMs, potentially accelerating research and development in fields relying on R for data analysis and machine learning.

# Acknowledgements

This project was partially supported by the Canadian Social Sciences & Humanities Research Council Tri-Agency Funding (funding reference: 192324).

# References



