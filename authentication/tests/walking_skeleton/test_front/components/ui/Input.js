import * as React from "react"

const Input = React.forwardRef(
    ({ className, type, ...props }, ref) => {
        const baseClasses = "flex h-10 w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-sm placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-green-500 focus:border-green-500 disabled:cursor-not-allowed disabled:opacity-50"
        const classes = `${baseClasses} ${className || ""}`
        
        return (
            <input
                type={type}
                className={classes}
                ref={ref}
                {...props}
            />
        )
    }
)
Input.displayName = "Input"

export { Input }

