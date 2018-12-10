no_rstudio <- !(Sys.getenv("RSTUDIO") == 1)
is_interactive <-  interactive()

makeActiveBinding(sym = 'd_', fun = devtools::document, env = globalenv())
makeActiveBinding(sym = 'l_', fun = devtools::load_all, env = globalenv())




if (is_interactive & no_rstudio  ){
    suppressPackageStartupMessages(require(colorout))
    setOutputColors(normal = 40, 
                    negnum = 209, 
                    zero = 226,
                    number = 214, 
                    date = 179, 
                    string = 85,
                    const = 35, 
                    false = 203, 
                    true = 78,
                    infinite = 39, 
                    index = 30, 
                    stderror = 213,
                    warn = 9, 
                    error = 1,
                    verbose = FALSE, 
                    zero.limit = NA)
    
}

options(prompt = 'R> ')

