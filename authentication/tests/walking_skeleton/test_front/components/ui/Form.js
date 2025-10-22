import * as React from "react"

const FormField = React.forwardRef(({ className, ...props }, ref) => (
    <div
        ref={ref}
        className={className || "space-y-2"}
        {...props}
    />
))
FormField.displayName = "FormField"

const FormItem = React.forwardRef(({ className, ...props }, ref) => (
    <div
        ref={ref}
        className={className || "space-y-2"}
        {...props}
    />
))
FormItem.displayName = "FormItem"

const FormLabel = React.forwardRef(({ className, ...props }, ref) => (
    <label
        ref={ref}
        className={className || "text-sm font-medium leading-none"}
        {...props}
    />
))
FormLabel.displayName = "FormLabel"

const FormMessage = React.forwardRef(({ className, children, ...props }, ref) => {
    const body = children ? String(children) : null

    if (!body) {
        return null
    }

    return (
        <p
            ref={ref}
            className={className || "text-sm font-medium text-red-600"}
            {...props}
        >
            {body}
        </p>
    )
})
FormMessage.displayName = "FormMessage"

export { FormField, FormItem, FormLabel, FormMessage }

