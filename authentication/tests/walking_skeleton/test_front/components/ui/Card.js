import * as React from "react"

const Card = React.forwardRef(({ className, ...props }, ref) => {
    const baseClasses = "rounded-lg border border-gray-200 bg-white text-gray-900 shadow-sm"
    const classes = `${baseClasses} ${className || ""}`
    
    return (
        <div
            ref={ref}
            className={classes}
            {...props}
        />
    )
})
Card.displayName = "Card"

const CardHeader = React.forwardRef(({ className, ...props }, ref) => {
    const baseClasses = "flex flex-col space-y-1.5 p-6"
    const classes = `${baseClasses} ${className || ""}`
    
    return (
        <div
            ref={ref}
            className={classes}
            {...props}
        />
    )
})
CardHeader.displayName = "CardHeader"

const CardTitle = React.forwardRef(({ className, ...props }, ref) => {
    const baseClasses = "text-2xl font-semibold leading-none tracking-tight"
    const classes = `${baseClasses} ${className || ""}`
    
    return (
        <h3
            ref={ref}
            className={classes}
            {...props}
        />
    )
})
CardTitle.displayName = "CardTitle"

const CardDescription = React.forwardRef(({ className, ...props }, ref) => {
    const baseClasses = "text-sm text-gray-600"
    const classes = `${baseClasses} ${className || ""}`
    
    return (
        <p
            ref={ref}
            className={classes}
            {...props}
        />
    )
})
CardDescription.displayName = "CardDescription"

const CardContent = React.forwardRef(({ className, ...props }, ref) => {
    const baseClasses = "p-6 pt-0"
    const classes = `${baseClasses} ${className || ""}`
    
    return (
        <div ref={ref} className={classes} {...props} />
    )
})
CardContent.displayName = "CardContent"

const CardFooter = React.forwardRef(({ className, ...props }, ref) => {
    const baseClasses = "flex items-center p-6 pt-0"
    const classes = `${baseClasses} ${className || ""}`
    
    return (
        <div
            ref={ref}
            className={classes}
            {...props}
        />
    )
})
CardFooter.displayName = "CardFooter"

export { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle }

