function Avatar({ imageUrl, name, variant }) {
  const className = `avatar avatar-${variant}`

  if (imageUrl) {
    return <img src={imageUrl} alt="" className={className} aria-hidden="true" />
  }

  return (
    <span className={className} aria-hidden="true">
      {name ? name.charAt(0) : ''}
    </span>
  )
}

export default Avatar
