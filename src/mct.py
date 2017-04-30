# mct.py

from MulticoreTSNE import MulticoreTSNE as TSNE
import numpy as np

"""Python module demonstrates passing MATLAB types to Python functions"""
def search(words):
    """Return list of words containing 'son'"""
    newlist = [w for w in words if 'son' in w]
    return newlist

def theend(words):
    """Append 'The End' to list of words"""
    words.append('The End')
    return words



def embed(X,n_samples):

	X = np.array(X)
	X = X.reshape(int(len(X)/n_samples),int(n_samples))
	tsne = TSNE(n_jobs=4)
	R = tsne.fit_transform(X)
    return R


