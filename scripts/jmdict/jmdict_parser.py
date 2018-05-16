import lxml.etree as Etree
import gzip

count = 0


class JmdictEntry(object):

    def __init__(self):
        self.id = 0
        self.readings = []
        self.writings = []
        self.tags = set()


def read_jmdict_impl(inf):
    entry = JmdictEntry()

    for ev, el in Etree.iterparse(inf, resolve_entities=False):
        if el.tag == 'ent_seq':
            entry.id = int(el.text)
        elif el.tag == 'keb':
            entry.writings += el.text
        elif el.tag == 'reb':
            entry.readings += el.text
        elif el.tag == 'pos':
            entry.tags += el.text
        elif el.tag == entry:
            yield entry
            entry = JmdictEntry()


def read_stream(inf, filename):
    if filename.endswith('.gz'):
        with gzip.GzipFile(filename=filename, fileobj=inf) as gzf:
            yield from read_stream(gzf, filename[:-3])
            return

    yield from read_jmdict_impl(inf)


def read_jmdict(filename):
    with open(filename, 'rb') as file:
        yield from read_stream(file, filename)
