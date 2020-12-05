import numpy as np
segments = 28 
bounds = np.linspace(0.0, 100.0, segments + 1)
centers =(bounds[1:] + bounds[:-1]) / 2
print(bounds)
print(centers)
